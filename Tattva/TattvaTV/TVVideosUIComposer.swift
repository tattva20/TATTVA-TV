import UIKit
import StreamingCore
import StreamingCoreAccessibility

@MainActor
public enum TVVideosUIComposer {
	public static func videosComposedWith(
		videos: [Video],
		selection: @escaping @MainActor (Video) -> Void
	) -> TVVideosViewController {
		let videosViewController = TVVideosViewController()

		videosViewController.onRefresh = { [weak videosViewController] in
			let controllers = videos.map { video in
				let cellController = TVVideoCellController(
					viewModel: VideoViewModel(title: video.title, description: video.description),
					selection: { selection(video) })
				return TVCellController(id: video, cellController)
			}
			videosViewController?.display(controllers)
		}

		return videosViewController
	}

	public static func videosComposedWith(
		videoLoader: @escaping () async throws -> Paginated<Video>,
		imageLoader: @escaping @Sendable (URL) async throws -> Data,
		selection: @escaping @MainActor (Video) -> Void
	) -> TVVideosViewController {
		let videosViewController = TVVideosViewController()
		let adapter = TVVideosLoaderPresentationAdapter(
			videoLoader: videoLoader,
			imageLoader: imageLoader,
			selection: selection)
		adapter.videosViewController = videosViewController
		adapter.announcer = UIKitAnnouncer()

		videosViewController.onRefresh = { adapter.loadVideos() }
		videosViewController.onLoadMore = { adapter.loadMoreIfAvailable() }
		videosViewController.onRetry = { adapter.loadVideos() }

		return videosViewController
	}
}
