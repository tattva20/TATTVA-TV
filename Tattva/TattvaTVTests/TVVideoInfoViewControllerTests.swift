import XCTest
import StreamingCore
@testable import TattvaTV

@MainActor
final class TVVideoInfoViewControllerTests: XCTestCase {

	func test_infoPanelTabTitleIsInfo() {
		let sut = TVVideoInfoViewController(video: makeVideo())

		XCTAssertEqual(sut.title, "Info")
	}

	func test_viewDidLoad_showsVideoTitleAndDescription() {
		let sut = TVVideoInfoViewController(video: makeVideo(title: "Big Buck Bunny", description: "A large and lovable rabbit."))

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.titleLabel.text, "Big Buck Bunny")
		XCTAssertEqual(sut.descriptionLabel.text, "A large and lovable rabbit.")
	}

	func test_formattedDuration_positionalForPositiveDurationNilForZero() {
		XCTAssertNil(TVVideoInfoViewController.formattedDuration(0))

		let formatted = TVVideoInfoViewController.formattedDuration(596)
		XCTAssertNotNil(formatted)
		XCTAssertTrue(formatted?.contains(":") == true, "Expected a positional M:SS duration, got \(formatted ?? "nil")")
	}

	// MARK: - Helpers

	private func makeVideo(title: String = "any", description: String? = "any description") -> Video {
		Video(
			id: UUID(),
			title: title,
			description: description,
			url: URL(string: "https://a-host.com/a.m3u8")!,
			thumbnailURL: URL(string: "https://a-host.com/thumb.jpg")!,
			duration: 596
		)
	}
}
