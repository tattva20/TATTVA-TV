import os
import UIKit
import Combine
import CoreData
import StreamingCore
import StreamingCorePlayback

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	private lazy var logger = Logger(subsystem: "com.tattva.TattvaTV", category: "main")

	private lazy var httpClient: HTTPClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))

	private lazy var store: VideoStore & VideoImageDataStore & StoreScheduler & Sendable = {
		do {
			return try CoreDataVideoStore(
				storeURL: NSPersistentContainer
					.defaultDirectoryURL()
					.appendingPathComponent("video-store.sqlite"))
		} catch {
			logger.fault("Failed to instantiate CoreData store: \(error.localizedDescription)")
			return InMemoryVideoStore()
		}
	}()

	private lazy var videoService = VideoService(httpClient: httpClient, store: store, logger: logger)

	private lazy var memoryMonitor: PollingMemoryMonitor = MemoryMonitorFactory.makeSystemMemoryMonitor()
	private lazy var bufferManager: AdaptiveBufferManager = AdaptiveBufferManager()
	private var bufferManagerBinding: AnyCancellable?

	private lazy var structuredLogger: any StreamingCore.Logger =
		LoggingConfiguration.makeLogger(subsystem: "com.tattva.TattvaTV")

	private lazy var analyticsStore: AnalyticsStore = {
		let persistent: AnalyticsStore
		do {
			persistent = try CoreDataAnalyticsStore(
				storeURL: NSPersistentContainer
					.defaultDirectoryURL()
					.appendingPathComponent("analytics-store.sqlite"))
		} catch {
			assertionFailure("Failed to instantiate CoreData analytics store: \(error.localizedDescription)")
			persistent = InMemoryAnalyticsStore()
		}
		return LoggingAnalyticsStore(decoratee: persistent, logger: structuredLogger)
	}()

	private lazy var analyticsLogger: PlaybackAnalyticsLogger =
		PlaybackAnalyticsService(store: analyticsStore)

	private lazy var navigationController = UINavigationController(
		rootViewController: TVVideosUIComposer.feedComposedWith(
			videoLoader: videoService.loadRemoteVideosWithLocalFallback,
			imageLoader: videoService.loadLocalImageWithRemoteFallback,
			selection: showPlayer))

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let windowScene = scene as? UIWindowScene else { return }
		let window = UIWindow(windowScene: windowScene)
		window.rootViewController = navigationController
		self.window = window
		window.makeKeyAndVisible()
		startBufferManagement()
	}

	private func startBufferManagement() {
		memoryMonitor.startMonitoring()
		bufferManagerBinding = memoryMonitor.statePublisher
			.sink { [bufferManager] state in
				bufferManager.updateMemoryState(state)
			}
	}

	private func showPlayer(for video: Video) {
		let info = TVVideoInfoViewController(video: video)
		let playerViewController = TVPlayerViewController(
			video: video,
			infoViewController: info,
			analyticsLogger: analyticsLogger,
			structuredLogger: structuredLogger,
			bufferManager: bufferManager)
		navigationController.pushViewController(playerViewController, animated: true)
	}
}
