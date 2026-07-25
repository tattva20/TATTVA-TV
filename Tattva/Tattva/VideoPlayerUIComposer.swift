//
//  VideoPlayerUIComposer.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreiOS
import StreamingCorePlayback

// MARK: - Associated Object Extension for Performance Adapter

private nonisolated(unsafe) var performanceAdapterKey: UInt8 = 0

public extension VideoPlayerViewController {
	var performanceAdapter: VideoPlayerPerformanceAdapter? {
		get {
			objc_getAssociatedObject(self, &performanceAdapterKey) as? VideoPlayerPerformanceAdapter
		}
		set {
			objc_setAssociatedObject(
				self,
				&performanceAdapterKey,
				newValue,
				.OBJC_ASSOCIATION_RETAIN_NONATOMIC
			)
		}
	}
}

// MARK: - Associated Object Extension for Stateful Player

private nonisolated(unsafe) var statefulPlayerKey: UInt8 = 0

public extension VideoPlayerViewController {
	var statefulPlayer: StatefulVideoPlayer? {
		get {
			objc_getAssociatedObject(self, &statefulPlayerKey) as? StatefulVideoPlayer
		}
		set {
			objc_setAssociatedObject(
				self,
				&statefulPlayerKey,
				newValue,
				.OBJC_ASSOCIATION_RETAIN_NONATOMIC
			)
		}
	}
}

private nonisolated(unsafe) var playbackCoordinatorKey: UInt8 = 0

extension VideoPlayerViewController {
	var playbackCoordinator: PlaybackCoordinator? {
		get {
			objc_getAssociatedObject(self, &playbackCoordinatorKey) as? PlaybackCoordinator
		}
		set {
			objc_setAssociatedObject(
				self,
				&playbackCoordinatorKey,
				newValue,
				.OBJC_ASSOCIATION_RETAIN_NONATOMIC
			)
		}
	}
}

private nonisolated(unsafe) var bufferAdapterKey: UInt8 = 0

extension VideoPlayerViewController {
	var bufferAdapter: AVPlayerBufferAdapterConcrete? {
		get {
			objc_getAssociatedObject(self, &bufferAdapterKey) as? AVPlayerBufferAdapterConcrete
		}
		set {
			objc_setAssociatedObject(
				self,
				&bufferAdapterKey,
				newValue,
				.OBJC_ASSOCIATION_RETAIN_NONATOMIC
			)
		}
	}
}

@MainActor
public enum VideoPlayerUIComposer {
	public static func videoPlayerComposedWith(
		video: Video,
		player: VideoPlayer? = nil,
		commentsController: UIViewController? = nil,
		analyticsLogger: PlaybackAnalyticsLogger? = nil,
		structuredLogger: (any StreamingCore.Logger)? = nil,
		bufferManager: (any BufferManager)? = nil
	) -> VideoPlayerViewController {
		let viewModel = VideoPlayerPresenter.map(video)
		let basePlayer = player ?? AVPlayerVideoPlayer()

		// Decorator chain: base player -> logging -> analytics
		var videoPlayer: VideoPlayer = basePlayer

		// Add structured logging decorator if provided
		if let logger = structuredLogger {
			videoPlayer = LoggingVideoPlayerDecorator(decoratee: videoPlayer, logger: logger)
		}

		// Add analytics decorator if provided
		if let analytics = analyticsLogger {
			videoPlayer = AnalyticsVideoPlayerDecorator(decoratee: videoPlayer, analyticsLogger: analytics)
		}

		// Wrap with stateful player for state machine control
		let stateMachine = DefaultPlaybackStateMachine()
		let statefulPlayer = StatefulVideoPlayer(decoratee: videoPlayer, stateMachine: stateMachine)

		let controller = VideoPlayerViewController(viewModel: viewModel, player: statefulPlayer)
		controller.statefulPlayer = statefulPlayer

		// Create and wire performance monitoring
		let performanceService = PlaybackPerformanceService()
		let bandwidthEstimator = NetworkBandwidthEstimator()
		let performanceAdapter = VideoPlayerPerformanceAdapter(
			performanceService: performanceService,
			bandwidthEstimator: bandwidthEstimator
		)
		performanceAdapter.startMonitoring(sessionID: UUID())
		controller.performanceAdapter = performanceAdapter

		if let commentsController = commentsController {
			controller.setCommentsController(commentsController)
		}

		// IMPORTANT: Do NOT use AppDelegate.orientationLock here!
		// Using orientation locks causes iOS to cache the restricted orientation mask,
		// which blocks physical rotation even after the lock is reset.
		// The correct approach is to use requestGeometryUpdate WITHOUT any orientation locking.
		// The view controller's supportedInterfaceOrientations (.allButUpsideDown) handles
		// what orientations are allowed - we just request the specific one we want.
		// Reference: commits 5473c40 and 4705375 show the original working implementation.
		controller.onFullscreenToggle = { [weak controller] in
			guard let controller = controller else { return }
			let isCurrentlyFullscreen = controller.isFullscreen

			if #available(iOS 16.0, *) {
				guard let windowScene = controller.view.window?.windowScene else { return }
				let targetOrientation: UIInterfaceOrientationMask = isCurrentlyFullscreen ? .portrait : .landscapeRight
				controller.setNeedsUpdateOfSupportedInterfaceOrientations()
				windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: targetOrientation)) { _ in }
			} else {
				if isCurrentlyFullscreen {
					let value = UIInterfaceOrientation.portrait.rawValue
					UIDevice.current.setValue(value, forKey: "orientation")
				} else {
					let value = UIInterfaceOrientation.landscapeRight.rawValue
					UIDevice.current.setValue(value, forKey: "orientation")
				}
				UIViewController.attemptRotationToDeviceOrientation()
			}
		}

		controller.loadViewIfNeeded()
		if let avPlayer = basePlayer as? AVPlayerVideoPlayer {
			avPlayer.attach(to: controller.playerView)

			let coordinator = PlaybackCoordinator(
				player: avPlayer.player,
				stateMachine: stateMachine,
				performanceAdapter: performanceAdapter,
				onTimeUpdate: { [weak controller] _ in controller?.updateTimeDisplay() }
			)
			coordinator.start()
			controller.playbackCoordinator = coordinator

			if let bufferManager = bufferManager {
				controller.bufferAdapter = AVPlayerBufferAdapter(
					player: avPlayer.player,
					bufferManager: bufferManager
				)
			}
		}

		let pipController = PictureInPictureController()
		pipController.setup(with: controller.playerView)
		controller.pipController = pipController

		controller.onPipToggle = { [weak controller] in
			controller?.pipController?.togglePictureInPicture()
		}

		return controller
	}
}
