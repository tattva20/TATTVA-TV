//
//  SceneDelegate.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import os
import UIKit
import Combine
import CoreData
import StreamingCore
import StreamingCoreiOS
import StreamingCorePlayback

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	private var videoPlayerFactory: ((Video) -> VideoPlayer)?
	private var _isAutoCleanupEnabled = false
	private var bufferManagerBinding: AnyCancellable?

	// MARK: - Public Properties for Testing

	var isAutoCleanupEnabled: Bool { _isAutoCleanupEnabled }

	lazy var memoryMonitor: PollingMemoryMonitor = {
		MemoryMonitorFactory.makeSystemMemoryMonitor()
	}()

	lazy var resourceCleanupCoordinator: ResourceCleanupCoordinator = {
		let videoCleaner = VideoCacheCleaner(
			deleteAction: { [store] in
				try store.deleteCachedVideos()
			}
		)
		return ResourceCleanupCoordinator(
			cleaners: [videoCleaner],
			memoryMonitor: memoryMonitor
		)
	}()

	lazy var bufferManager: AdaptiveBufferManager = {
		AdaptiveBufferManager()
	}()

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

	private lazy var analyticsLogger: PlaybackAnalyticsLogger = {
		PlaybackAnalyticsService(store: analyticsStore)
	}()

	private lazy var structuredLogger: any StreamingCore.Logger = {
		LoggingConfiguration.makeLogger(subsystem: "com.tattva.Tattva")
	}()

	private lazy var httpClient: HTTPClient = {
		URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
	}()

	private lazy var logger = Logger(subsystem: "com.tattva.Tattva", category: "main")

	private lazy var store: VideoStore & VideoImageDataStore & StoreScheduler & Sendable = {
		do {
			return try CoreDataVideoStore(
				storeURL: NSPersistentContainer
					.defaultDirectoryURL()
					.appendingPathComponent("video-store.sqlite"))
		} catch {
			assertionFailure("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
			logger.fault("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
			return InMemoryVideoStore()
		}
	}()

	private lazy var videoService = VideoService(httpClient: httpClient, store: store, logger: logger)

	private lazy var navigationController = UINavigationController(
		rootViewController: VideosUIComposer.videosComposedWith(
			videoLoader: videoService.loadRemoteVideosWithLocalFallback,
			imageLoader: videoService.loadLocalImageWithRemoteFallback,
			selection: showVideoPlayer))

	convenience init(
		httpClient: HTTPClient,
		store: VideoStore & VideoImageDataStore & StoreScheduler & Sendable,
		videoPlayerFactory: ((Video) -> VideoPlayer)? = nil
	) {
		self.init()
		self.httpClient = httpClient
		self.store = store
		self.videoPlayerFactory = videoPlayerFactory
	}

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let scene = (scene as? UIWindowScene) else { return }

		configureAudioSession()
		window = UIWindow(windowScene: scene)
		configureWindow()
	}

	private func configureAudioSession() {
		guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

		let audioSessionConfigurator = AVAudioSessionAdapter()
		try? audioSessionConfigurator.configureForPlayback()
	}

	func configureWindow() {
		window?.rootViewController = navigationController
		window?.makeKeyAndVisible()
		enableAutoCleanup()
		bindBufferManagerToMemory()
	}

	private func bindBufferManagerToMemory() {
		bufferManagerBinding = memoryMonitor.statePublisher
			.sink { [bufferManager] state in
				bufferManager.updateMemoryState(state)
			}
	}

	private func enableAutoCleanup() {
		guard !_isAutoCleanupEnabled else { return }
		_isAutoCleanupEnabled = true
		resourceCleanupCoordinator.enableAutoCleanup()
	}

	func sceneWillResignActive(_ scene: UIScene) {
		videoService.validateCache()
	}

	private func showVideoPlayer(for video: Video) {
		let commentsController = VideoCommentsUIComposer.commentsComposedWith(
			commentsLoader: videoService.loadComments(for: video))

		let player = videoPlayerFactory?(video)
		let videoPlayerController = VideoPlayerUIComposer.videoPlayerComposedWith(
			video: video,
			player: player,
			commentsController: commentsController,
			analyticsLogger: analyticsLogger,
			structuredLogger: structuredLogger,
			bufferManager: bufferManager)
		navigationController.pushViewController(videoPlayerController, animated: true)
	}
}
