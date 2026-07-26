import UIKit
import StreamingCore
import StreamingCoreAccessibility

@MainActor
final class TVVideosLoaderPresentationAdapter {
	private let videoLoader: () async throws -> Paginated<Video>
	private let imageLoader: @Sendable (URL) async throws -> Data
	private let selection: @MainActor (Video) -> Void

	weak var videosViewController: TVVideosViewController?
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

	static let loadErrorMessage = "Couldn't load videos. Please try again."

	func loadVideos() {
		guard !isLoading else { return }
		isLoading = true
		videosViewController?.display(errorMessage: nil)
		videosViewController?.display(isLoading: true)
		Task.immediate { @MainActor in
			defer { self.isLoading = false }
			do {
				let page = try await self.videoLoader()
				self.accumulatedVideos = page.items
				self.loadMore = page.loadMore
				self.videosViewController?.display(isLoading: false)
				self.display()
			} catch {
				self.videosViewController?.display(isLoading: false)
				self.videosViewController?.display(errorMessage: Self.loadErrorMessage)
				self.announcer?.announce(Self.loadErrorMessage)
			}
		}
	}

	func loadMoreIfAvailable() {
		guard !isLoading, let loadMore else { return }
		isLoading = true
		Task.immediate { @MainActor in
			defer { self.isLoading = false }
			do {
				let page = try await loadMore()
				self.accumulatedVideos += page.items
				self.loadMore = page.loadMore
				self.display()
			} catch {}
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
		videosViewController?.display(controllers)
		announcer?.announce("\(accumulatedVideos.count) videos")
	}
}
