import XCTest
import UIKit
import StreamingCore
@testable import TattvaTV

@MainActor
final class TVVideosPaginationTests: XCTestCase {
	override func tearDown() {
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	func test_displayingLastPoster_loadsMoreAndAppendsVideos() async {
		let secondPageVideos = [makeVideo(title: "Third")]
		let firstPage = Paginated(
			items: [makeVideo(title: "First"), makeVideo(title: "Second")],
			loadMore: { Paginated(items: secondPageVideos) })

		let sut = TVVideosUIComposer.videosComposedWith(
			videoLoader: { firstPage },
			imageLoader: { _ in Data() },
			selection: { _ in })

		sut.simulateAppearance()
		await eventually { sut.numberOfRenderedPosters() == 2 }

		sut.simulateDisplayingLastPoster()

		await eventually { sut.numberOfRenderedPosters() == 3 }
		XCTAssertEqual(sut.numberOfRenderedPosters(), 3, "Expected the second page to be appended after the last poster is displayed")
		XCTAssertEqual(sut.posterTitle(at: 2), "Third")
	}

	func test_displayingLastPoster_withoutMorePages_doesNotGrow() async {
		let onlyPage = Paginated(items: [makeVideo(title: "Only")])

		let sut = TVVideosUIComposer.videosComposedWith(
			videoLoader: { onlyPage },
			imageLoader: { _ in Data() },
			selection: { _ in })

		sut.simulateAppearance()
		await eventually { sut.numberOfRenderedPosters() == 1 }

		sut.simulateDisplayingLastPoster()
		await eventually { true }

		XCTAssertEqual(sut.numberOfRenderedPosters(), 1, "Expected no growth when the page has no loadMore")
	}

	// MARK: - Helpers

	private func eventually(_ condition: () -> Bool, iterations: Int = 100) async {
		for _ in 0..<iterations {
			if condition() { return }
			await Task.yield()
		}
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
extension TVVideosViewController {
	func simulateDisplayingLastPoster() {
		let lastIndex = collectionView.numberOfItems(inSection: 0) - 1
		guard lastIndex >= 0, let dataSource = collectionView.dataSource else { return }
		let indexPath = IndexPath(item: lastIndex, section: 0)
		let cell = dataSource.collectionView(collectionView, cellForItemAt: indexPath)
		collectionView.delegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
	}
}
