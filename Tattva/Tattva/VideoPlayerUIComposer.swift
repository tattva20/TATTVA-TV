//
//  VideoPlayerUIComposer.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import Combine
import StreamingCore
import StreamingCoreiOS
import StreamingCorePlayback

final class NetworkBitrateBinding {
	private let monitor: NetworkQualityMonitor
	private let cancellable: AnyCancellable

	init(monitor: NetworkQualityMonitor, cancellable: AnyCancellable) {
		self.monitor = monitor
		self.cancellable = cancellable
	}

	deinit {
		let monitor = self.monitor
		Task { await monitor.stopMonitoring() }
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
		bufferManager: (any BufferManager)? = nil,
		memoryStatePublisher: AnyPublisher<MemoryState, Never>? = nil
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
			Task { await analytics.startSession(videoID: video.id, videoTitle: video.title, deviceInfo: .current(), appVersion: AppVersion.current) }
		}

		// Wrap with stateful player for state machine control
		let stateMachine = DefaultPlaybackStateMachine()
		let statefulPlayer = StatefulVideoPlayer(decoratee: videoPlayer, stateMachine: stateMachine)

		let controller = VideoPlayerViewController(viewModel: viewModel, player: statefulPlayer)

		// Create and wire performance monitoring
		let performanceService = PlaybackPerformanceService()
		let bandwidthEstimator = NetworkBandwidthEstimator()
		let performanceAdapter = VideoPlayerPerformanceAdapter(
			performanceService: performanceService,
			bandwidthEstimator: bandwidthEstimator
		)
		performanceAdapter.startMonitoring(sessionID: UUID())

		var performanceAlertLogging: PerformanceAlertLoggingBinding?
		if let structuredLogger {
			performanceAlertLogging = PerformanceAlertLoggingBinding(
				alerts: performanceService.alertPublisher,
				logger: structuredLogger
			)
		}

		var memoryPerformanceCancellable: AnyCancellable?
		if let memoryStatePublisher {
			memoryPerformanceCancellable = memoryStatePublisher
				.receive(on: RunLoop.main)
				.sink { [weak performanceAdapter] state in
					performanceAdapter?.updateMemory(
						usedMB: state.usedMB,
						pressure: state.pressureLevel(thresholds: .default))
				}
		}

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

		var playbackCoordinator: PlaybackCoordinator?
		var bufferAdapter: AVPlayerBufferAdapterConcrete?
		var networkBitrateBinding: NetworkBitrateBinding?

		if let avPlayer = basePlayer as? AVPlayerVideoPlayer {
			avPlayer.attach(to: controller.playerView)

			let coordinator = PlaybackCoordinator(
				player: avPlayer.player,
				stateMachine: stateMachine,
				performanceAdapter: performanceAdapter,
				onTimeUpdate: { [weak controller] _ in controller?.updateTimeDisplay() }
			)
			coordinator.start()
			playbackCoordinator = coordinator

			let retryController = PlaybackRetryController(reload: { [weak avPlayer] in avPlayer?.reload() })
			coordinator.onPlaybackFailed = { retryController.playbackDidFail() }
			coordinator.onPlaybackRecovered = { retryController.playbackDidRecover() }

			if let bufferManager = bufferManager {
				bufferAdapter = AVPlayerBufferAdapter(
					player: avPlayer.player,
					bufferManager: bufferManager
				)
			}

			let networkMonitor = NetworkQualityMonitor()
			let bitratePolicy = NetworkBitratePolicy()
			let bitrateCancellable = networkMonitor.qualityPublisher
				.receive(on: RunLoop.main)
				.sink { [weak coordinator, weak performanceAdapter, bufferManager] quality in
					coordinator?.setPreferredPeakBitRate(bitratePolicy.peakBitRate(for: quality))
					bufferManager?.updateNetworkQuality(quality)
					performanceAdapter?.updateNetworkQuality(quality)
				}
			Task { await networkMonitor.startMonitoring() }
			networkBitrateBinding = NetworkBitrateBinding(
				monitor: networkMonitor,
				cancellable: bitrateCancellable
			)
		}

		let pipController = PictureInPictureController()
		pipController.setup(with: controller.playerView)
		pipController.onRestoreUserInterface = { [weak controller] completion in
			guard let controller, let navigationController = controller.navigationController else {
				completion(true)
				return
			}
			if navigationController.topViewController !== controller {
				navigationController.popToViewController(controller, animated: true)
			}
			completion(true)
		}
		controller.pipController = pipController

		controller.onPipToggle = { [weak controller] in
			controller?.pipController?.togglePictureInPicture()
		}

		controller.playbackCollaborators = PlaybackCollaborators(
			statefulPlayer: statefulPlayer,
			performanceAdapter: performanceAdapter,
			playbackCoordinator: playbackCoordinator,
			bufferAdapter: bufferAdapter,
			networkBitrateBinding: networkBitrateBinding,
			performanceAlertLogging: performanceAlertLogging,
			memoryPerformanceCancellable: memoryPerformanceCancellable
		)

		return controller
	}
}
