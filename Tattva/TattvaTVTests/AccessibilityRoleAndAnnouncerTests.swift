import XCTest
import UIKit
import StreamingCore
import StreamingCoreAccessibility

@MainActor
final class AccessibilityRoleTests: XCTestCase {

	func test_role_mapsToMatchingTraits() {
		XCTAssertTrue(AccessibilityRole.button.traits.contains(.button))
		XCTAssertTrue(AccessibilityRole.image.traits.contains(.image))
		XCTAssertTrue(AccessibilityRole.header.traits.contains(.header))
		XCTAssertEqual(AccessibilityRole.none.traits, .none)
	}

	func test_accessibleWithRole_appliesTheMappedTraits() {
		let view = UIView()

		view.accessible(label: "Poster", role: .button)

		XCTAssertEqual(view.accessibilityLabel, "Poster")
		XCTAssertTrue(view.accessibilityTraits.contains(.button))
	}
}

@MainActor
final class AnnouncingResourceViewTests: XCTestCase {

	func test_display_forwardsToDecoratee() {
		let (sut, decoratee, _) = makeSUT { _ in nil }

		sut.display("a view model")

		XCTAssertEqual(decoratee.displayed, ["a view model"])
	}

	func test_display_announcesTheDescribedMessage() {
		let (sut, _, announcer) = makeSUT { "\($0) loaded" }

		sut.display("12 videos")

		XCTAssertEqual(announcer.announcements, ["12 videos loaded"])
	}

	func test_display_doesNotAnnounceWhenThereIsNothingToDescribe() {
		let (sut, _, announcer) = makeSUT { _ in nil }

		sut.display("a view model")

		XCTAssertTrue(announcer.announcements.isEmpty)
	}

	// MARK: - Helpers

	private func makeSUT(
		describe: @escaping (String) -> String?
	) -> (AnnouncingResourceView<ViewSpy>, ViewSpy, AnnouncerSpy) {
		let decoratee = ViewSpy()
		let announcer = AnnouncerSpy()
		let sut = AnnouncingResourceView(decoratee: decoratee, announcer: announcer, describe: describe)
		return (sut, decoratee, announcer)
	}

	private final class ViewSpy: ResourceView {
		typealias ResourceViewModel = String
		private(set) var displayed = [String]()
		func display(_ viewModel: String) { displayed.append(viewModel) }
	}

	private final class AnnouncerSpy: Announcer {
		private(set) var announcements = [String]()
		func announce(_ message: String) { announcements.append(message) }
	}
}
