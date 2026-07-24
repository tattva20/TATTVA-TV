import XCTest
@testable import TattvaTV

@MainActor
final class TVVideoPosterCellTests: XCTestCase {

	func test_configure_setsTitleText() {
		let sut = TVVideoPosterCell(frame: .zero)

		sut.configure(title: "Big Buck Bunny")

		XCTAssertEqual(sut.titleText, "Big Buck Bunny")
	}

	func test_configure_exposesCellAsAccessibilityElementLabeledWithTitle() {
		let sut = TVVideoPosterCell(frame: .zero)

		sut.configure(title: "Big Buck Bunny")

		XCTAssertTrue(sut.isAccessibilityElement, "The poster cell should be a single VoiceOver element")
		XCTAssertEqual(sut.accessibilityLabel, "Big Buck Bunny")
		XCTAssertTrue(sut.accessibilityTraits.contains(.button), "Selecting a poster plays the video, so it should read as actionable")
	}

	func test_prepareForReuse_clearsTitleAndAccessibilityLabel() {
		let sut = TVVideoPosterCell(frame: .zero)
		sut.configure(title: "Big Buck Bunny")

		sut.prepareForReuse()

		XCTAssertNil(sut.titleText)
		XCTAssertNil(sut.accessibilityLabel)
	}
}
