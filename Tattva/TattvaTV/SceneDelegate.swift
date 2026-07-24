import os
import UIKit
import CoreData
import StreamingCore
import StreamingCorePlayback

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	private lazy var logger = Logger(subsystem: "com.octavio.rojas.TattvaTV", category: "main")

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
	}

	private func showPlayer(for video: Video) {
		let info = TVVideoInfoViewController(video: video)
		let playerViewController = TVPlayerViewController(video: video, infoViewController: info)
		navigationController.pushViewController(playerViewController, animated: true)
	}
}
