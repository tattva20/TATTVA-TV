import UIKit
import StreamingCore

public extension AccessibilityRole {
	var traits: UIAccessibilityTraits {
		switch self {
		case .none: return .none
		case .button: return .button
		case .image: return .image
		case .header: return .header
		case .staticText: return .staticText
		case .adjustable: return .adjustable
		case .link: return .link
		@unknown default: return .none
		}
	}
}

public extension UIView {
	@discardableResult
	func accessible(
		label: String? = nil,
		value: String? = nil,
		hint: String? = nil,
		role: AccessibilityRole,
		isElement: Bool = true
	) -> Self {
		accessible(label: label, value: value, hint: hint, traits: role.traits, isElement: isElement)
	}
}
