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
	}

	public static func playerComposedWith(
		video: Video,
		basePlayer: AVPlayerVideoPlayer = AVPlayerVideoPlayer(),
		analyticsLogger: PlaybackAnalyticsLogger? = nil,
		structuredLogger: (any StreamingCore.Logger)? = nil,
		bufferManager: (any BufferManager)? = nil
	) -> Bundle {
		var videoPlayer: VideoPlayer = basePlayer

		if let structuredLogger {
			videoPlayer = LoggingVideoPlayerDecorator(decoratee: videoPlayer, logger: structuredLogger)
		}

		if let analyticsLogger {
			videoPlayer = AnalyticsVideoPlayerDecorator(decoratee: videoPlayer, analyticsLogger: analyticsLogger)
		}

		let stateMachine = DefaultPlaybackStateMachine()
		let statefulPlayer = StatefulVideoPlayer(decoratee: videoPlayer, stateMachine: stateMachine)

		let performanceAdapter = VideoPlayerPerformanceAdapter(
			performanceService: PlaybackPerformanceService(),
			bandwidthEstimator: NetworkBandwidthEstimator()
		)
		performanceAdapter.startMonitoring(sessionID: UUID())

		let coordinator = PlaybackCoordinator(
			player: basePlayer.player,
			stateMachine: stateMachine,
			performanceAdapter: performanceAdapter
		)
		coordinator.start()

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
			networkBinding: TVNetworkBitrateBinding(monitor: networkMonitor, cancellable: bitrateCancellable)
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
