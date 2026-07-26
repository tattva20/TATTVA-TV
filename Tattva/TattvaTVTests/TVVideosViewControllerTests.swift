import XCTest
import UIKit
import StreamingCore
@testable import TattvaTV

@MainActor
final class TVVideosViewControllerTests: XCTestCase {
	override func tearDown() {
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	func test_display_rendersOnePosterPerVideo() {
		let sut = makeSUT(videos: [makeVideo(title: "First"), makeVideo(title: "Second")])

		sut.simulateAppearance()

		XCTAssertEqual(sut.numberOfRenderedPosters(), 2)
		XCTAssertEqual(sut.posterTitle(at: 0), "First")
		XCTAssertEqual(sut.posterTitle(at: 1), "Second")
	}

	func test_posterSelection_notifiesSelectionHandler() {
		let selected = makeVideo(title: "Tap me")
		var selectedVideos = [Video]()
		let sut = makeSUT(videos: [selected], selection: { selectedVideos.append($0) })

		sut.simulateAppearance()
		sut.simulatePosterSelection(at: 0)

		XCTAssertEqual(selectedVideos, [selected])
	}

	// MARK: - Helpers

	private func makeSUT(
		videos: [Video],
		selection: @escaping @MainActor (Video) -> Void = { _ in },
		file: StaticString = #filePath,
		line: UInt = #line
	) -> TVVideosViewController {
		let sut = TVVideosUIComposer.videosComposedWith(videos: videos, selection: selection)
		return sut
	}

	private func makeVideo(title: String) -> Video {
		Video(
			id: UUID(),
			title: title,
			description: "any description",
			url: URL(string: "https://any-url.com/\(title).m3u8")!,
			thumbnailURL: URL(string: "https://any-url.com/\(title).jpg")!,
			duration: 0
		)
	}
}

@MainActor
extension TVVideosViewController {
	func simulateAppearance() {
		loadViewIfNeeded()
		collectionView.frame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
		collectionView.layoutIfNeeded()
	}

	func numberOfRenderedPosters() -> Int {
		guard collectionView.numberOfSections > 0 else { return 0 }
		return collectionView.numberOfItems(inSection: 0)
	}

	private func posterCell(at index: Int) -> TVVideoPosterCell? {
		let indexPath = IndexPath(item: index, section: 0)
		return collectionView.dataSource?.collectionView(collectionView, cellForItemAt: indexPath) as? TVVideoPosterCell
	}

	func posterTitle(at index: Int) -> String? {
		posterCell(at: index)?.titleText
	}

	func simulatePosterSelection(at index: Int) {
		let indexPath = IndexPath(item: index, section: 0)
		collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
	}
}
