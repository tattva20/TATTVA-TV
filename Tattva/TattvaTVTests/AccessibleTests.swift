import XCTest
import UIKit
import StreamingCoreAccessibility

@MainActor
final class AccessibleTests: XCTestCase {

	func test_accessible_appliesEveryFieldOfTheSpec() {
		let view = UIView()

		view.accessible(AccessibilitySpec(
			isElement: true, label: "Label", value: "Value", hint: "Hint", traits: .button
		))

		XCTAssertTrue(view.isAccessibilityElement)
		XCTAssertEqual(view.accessibilityLabel, "Label")
		XCTAssertEqual(view.accessibilityValue, "Value")
		XCTAssertEqual(view.accessibilityHint, "Hint")
		XCTAssertTrue(view.accessibilityTraits.contains(.button))
	}

	func test_accessibleWithParameters_appliesValues() {
		let view = UIView()

		view.accessible(label: "Poster", hint: "Plays the video", traits: .button)

		XCTAssertEqual(view.accessibilityLabel, "Poster")
		XCTAssertEqual(view.accessibilityHint, "Plays the video")
		XCTAssertTrue(view.accessibilityTraits.contains(.button))
	}

	func test_accessible_isElementFalse_hidesFromVoiceOver() {
		let view = UIView()

		view.accessible(.init(isElement: false))

		XCTAssertFalse(view.isAccessibilityElement)
	}

	func test_accessible_returnsSelfForChaining() {
		let view = UIView()

		let returned = view.accessible(label: "X")

		XCTAssertTrue(returned === view)
	}
}
