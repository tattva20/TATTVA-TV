import XCTest
import UIKit
import StreamingCore
@testable import TattvaTV

@MainActor
final class TVVideosLoaderIntegrationTests: XCTestCase {
	override func tearDown() {
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	func test_onAppearance_rendersPostersLoadedFromVideoLoader() async {
		let videos = [makeVideo(title: "First"), makeVideo(title: "Second")]
		let sut = makeSUT(videoResult: .success(paginated(videos)))

		sut.simulateAppearance()

		await eventually { sut.numberOfRenderedPosters() == 2 }
		XCTAssertEqual(sut.numberOfRenderedPosters(), 2)
		XCTAssertEqual(sut.posterTitle(at: 0), "First")
		XCTAssertEqual(sut.posterTitle(at: 1), "Second")
	}

	func test_posterDisplay_requestsThumbnailImageForVideoURL() async {
		let video = makeVideo(title: "One")
		let imageLoader = ImageLoaderSpy()
		let sut = makeSUT(videoResult: .success(paginated([video])), imageLoader: imageLoader)

		sut.simulateAppearance()
		await eventually { sut.numberOfRenderedPosters() == 1 }
		_ = sut.posterTitle(at: 0) // configures the cell, triggering the image request

		await eventually { imageLoader.requestedURLs.contains(video.thumbnailURL) }
		XCTAssertTrue(
			imageLoader.requestedURLs.contains(video.thumbnailURL),
			"Expected the poster to request its thumbnail image for the video's thumbnail URL")
	}

	// MARK: - Helpers

	private func makeSUT(
		videoResult: Result<Paginated<Video>, Error>,
		imageLoader: ImageLoaderSpy = ImageLoaderSpy()
	) -> TVVideosViewController {
		TVVideosUIComposer.videosComposedWith(
			videoLoader: { try videoResult.get() },
			imageLoader: { url in try await imageLoader.load(url) },
			selection: { _ in })
	}

	private func eventually(_ condition: () -> Bool, iterations: Int = 100) async {
		for _ in 0..<iterations {
			if condition() { return }
			await Task.yield()
		}
	}

	private func paginated(_ videos: [Video]) -> Paginated<Video> {
		Paginated(items: videos)
	}

	private func makeVideo(title: String) -> Video {
		Video(
			id: UUID(),
			title: title,
			description: nil,
			url: URL(string: "https://any-url.com/\(title).m3u8")!,
			thumbnailURL: URL(string: "https://any-url.com/\(title).jpg")!,
			duration: 0)
	}
}

@MainActor
private final class ImageLoaderSpy {
	private(set) var requestedURLs = [URL]()

	func load(_ url: URL) async throws -> Data {
		requestedURLs.append(url)
		return Data()
	}
}
