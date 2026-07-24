import XCTest
import StreamingCore
@testable import TattvaTV

@MainActor
final class TVCommentCellTests: XCTestCase {

	func test_configure_exposesCellAsSingleAccessibilityElementReadingWhoWhatWhen() {
		let sut = TVCommentCell(frame: .zero)
		let viewModel = VideoCommentViewModel(message: "Great video", date: "2 days ago", username: "lucero")

		sut.configure(with: viewModel)

		XCTAssertTrue(sut.isAccessibilityElement, "A comment should read as one VoiceOver element, not three fragments")
		XCTAssertEqual(sut.accessibilityLabel, "lucero. Great video. 2 days ago")
	}
}
