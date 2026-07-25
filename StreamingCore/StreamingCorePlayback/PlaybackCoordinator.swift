//
//  PlaybackCoordinator.swift
//  StreamingCorePlayback
//
//  Copyright by Octavio Rojas all rights reserved.
//
import AVFoundation
import StreamingCore

@MainActor
public final class PlaybackCoordinator {
	private let player: AVPlayer
	private let stateMachine: DefaultPlaybackStateMachine
	private let performanceAdapter: VideoPlayerPerformanceAdapter
	private let onTimeUpdate: @MainActor (TimeInterval) -> Void

	public var onPlaybackFailed: (() -> Void)?
	public var onPlaybackRecovered: (() -> Void)?

	private(set) var stateAdapter: AVPlayerStateAdapter?
	private var performanceObserver: AVPlayerPerformanceObserver?
	private nonisolated(unsafe) var timeObserverToken: Any?
	private nonisolated(unsafe) var stallRecoveryToken: Any?

	public var isObserving: Bool {
		stateAdapter?.isObserving ?? false
	}

	public init(
		player: AVPlayer,
		stateMachine: DefaultPlaybackStateMachine,
		performanceAdapter: VideoPlayerPerformanceAdapter,
		onTimeUpdate: @escaping @MainActor (TimeInterval) -> Void = { _ in }
	) {
		self.player = player
		self.stateMachine = stateMachine
		self.performanceAdapter = performanceAdapter
		self.onTimeUpdate = onTimeUpdate
	}

	public func start() {
		guard stateAdapter == nil else { return }

		let stateMachine = self.stateMachine
		let adapter = AVPlayerStateAdapter(player: player, onAction: { [weak self] action in
			Task { @MainActor in
				stateMachine.send(action)
				self?.handle(action)
			}
		})
		adapter.startObserving()
		stateAdapter = adapter

		let observer = AVPlayerPerformanceObserver(player: player)
		observer.startObserving()
		performanceAdapter.observePlayer(observer)
		performanceObserver = observer

		let onTimeUpdate = self.onTimeUpdate
		let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
		timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
			MainActor.assumeIsolated { onTimeUpdate(time.seconds) }
		}

		stallRecoveryToken = NotificationCenter.default.addObserver(
			forName: AVPlayerItem.playbackStalledNotification,
			object: player.currentItem,
			queue: .main
		) { [weak self] _ in
			MainActor.assumeIsolated { self?.player.play() }
		}
	}

	deinit {
		if let timeObserverToken {
			player.removeTimeObserver(timeObserverToken)
		}
		if let stallRecoveryToken {
			NotificationCenter.default.removeObserver(stallRecoveryToken)
		}
	}

	public func stop() {
		if let timeObserverToken {
			player.removeTimeObserver(timeObserverToken)
			self.timeObserverToken = nil
		}
		if let stallRecoveryToken {
			NotificationCenter.default.removeObserver(stallRecoveryToken)
			self.stallRecoveryToken = nil
		}
		stateAdapter?.stopObserving()
		stateAdapter = nil
		performanceObserver?.stopObserving()
		performanceObserver = nil
	}

	public func setPreferredPeakBitRate(_ bitsPerSecond: Double) {
		player.currentItem?.preferredPeakBitRate = max(0, bitsPerSecond)
	}

	private func handle(_ action: PlaybackAction) {
		switch action {
		case .didFail:
			onPlaybackFailed?()
		case .didStartPlaying:
			onPlaybackRecovered?()
		default:
			break
		}
	}
}
