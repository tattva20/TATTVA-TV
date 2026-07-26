import AVFoundation
import Combine
import StreamingCore
import StreamingCorePlayback

@MainActor
public enum TVPlayerComposer {
	public struct Bundle {
		public let player: AVPlayer
		let statefulPlayer: StatefulVideoPlayer
		let coordinator: PlaybackCoordinator
		let performanceAdapter: VideoPlayerPerformanceAdapter
		let bufferAdapter: AVPlayerBufferAdapterConcrete?
		let networkBinding: TVNetworkBitrateBinding?
		let performanceAlertLogging: PerformanceAlertLoggingBinding?
		let memoryPerformanceCancellable: AnyCancellable?
	}

	public static func playerComposedWith(
		video: Video,
		basePlayer: AVPlayerVideoPlayer = AVPlayerVideoPlayer(),
		analyticsLogger: PlaybackAnalyticsLogger? = nil,
		structuredLogger: (any StreamingCore.Logger)? = nil,
		bufferManager: (any BufferManager)? = nil,
		memoryStatePublisher: AnyPublisher<MemoryState, Never>? = nil
	) -> Bundle {
		var videoPlayer: VideoPlayer = basePlayer

		if let structuredLogger {
			videoPlayer = LoggingVideoPlayerDecorator(decoratee: videoPlayer, logger: structuredLogger)
		}

		if let analyticsLogger {
			videoPlayer = AnalyticsVideoPlayerDecorator(decoratee: videoPlayer, analyticsLogger: analyticsLogger)
			Task { await analyticsLogger.startSession(videoID: video.id, videoTitle: video.title, deviceInfo: .current(), appVersion: AppVersion.current) }
		}

		let stateMachine = DefaultPlaybackStateMachine()
		let statefulPlayer = StatefulVideoPlayer(decoratee: videoPlayer, stateMachine: stateMachine)

		let performanceService = PlaybackPerformanceService()
		let performanceAdapter = VideoPlayerPerformanceAdapter(
			performanceService: performanceService,
			bandwidthEstimator: NetworkBandwidthEstimator()
		)
		performanceAdapter.startMonitoring(sessionID: UUID())

		var performanceAlertLogging: PerformanceAlertLoggingBinding?
		if let structuredLogger {
			performanceAlertLogging = PerformanceAlertLoggingBinding(
				alerts: performanceService.alertPublisher,
				logger: structuredLogger)
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

		let coordinator = PlaybackCoordinator(
			player: basePlayer.player,
			stateMachine: stateMachine,
			performanceAdapter: performanceAdapter
		)
		coordinator.start()

		let retryController = PlaybackRetryController(reload: { [weak basePlayer] in basePlayer?.reload() })
		coordinator.onPlaybackFailed = { retryController.playbackDidFail() }
		coordinator.onPlaybackRecovered = { retryController.playbackDidRecover() }

		let bufferAdapter = bufferManager.map {
			AVPlayerBufferAdapter(player: basePlayer.player, bufferManager: $0)
		}

		basePlayer.load(url: video.url)

		if let bufferAdapter, let item = basePlayer.player.currentItem {
			bufferAdapter.applyToNewItem(item)
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

		return Bundle(
			player: basePlayer.player,
			statefulPlayer: statefulPlayer,
			coordinator: coordinator,
			performanceAdapter: performanceAdapter,
			bufferAdapter: bufferAdapter,
			networkBinding: TVNetworkBitrateBinding(monitor: networkMonitor, cancellable: bitrateCancellable),
			performanceAlertLogging: performanceAlertLogging,
			memoryPerformanceCancellable: memoryPerformanceCancellable
		)
	}
}

final class TVNetworkBitrateBinding {
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
