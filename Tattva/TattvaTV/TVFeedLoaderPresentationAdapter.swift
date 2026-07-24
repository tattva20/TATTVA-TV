import UIKit
import StreamingCore
import StreamingCoreAccessibility

@MainActor
final class TVFeedLoaderPresentationAdapter {
	private let videoLoader: () async throws -> Paginated<Video>
	private let imageLoader: @Sendable (URL) async throws -> Data
	private let selection: @MainActor (Video) -> Void

	weak var feedViewController: TVVideoFeedViewController?
	var announcer: Announcer?

	private var accumulatedVideos: [Video] = []
	private var loadMore: (@Sendable () async throws -> Paginated<Video>)?
	private var isLoading = false

	init(
		videoLoader: @escaping () async throws -> Paginated<Video>,
		imageLoader: @escaping @Sendable (URL) async throws -> Data,
		selection: @escaping @MainActor (Video) -> Void
	) {
		self.videoLoader = videoLoader
		self.imageLoader = imageLoader
		self.selection = selection
	}

	func loadFeed() {
		guard !isLoading else { return }
		isLoading = true
		Task.immediate { @MainActor in
			defer { self.isLoading = false }
			guard let page = try? await self.videoLoader() else { return }
			self.accumulatedVideos = page.items
			self.loadMore = page.loadMore
			self.display()
		}
	}

	func loadMoreIfAvailable() {
		guard !isLoading, let loadMore else { return }
		isLoading = true
		Task.immediate { @MainActor in
			defer { self.isLoading = false }
			guard let page = try? await loadMore() else { return }
			self.accumulatedVideos += page.items
			self.loadMore = page.loadMore
			self.display()
		}
	}

	private func display() {
		let controllers = accumulatedVideos.map { video in
			let cellController = TVVideoCellController(
				viewModel: VideoViewModel(title: video.title, description: video.description),
				imageLoader: imageLoader,
				thumbnailURL: video.thumbnailURL,
				selection: { [selection] in selection(video) })
			return TVCellController(id: video, cellController)
		}
		feedViewController?.display(controllers)
		announcer?.announce("\(accumulatedVideos.count) videos")
	}
}
