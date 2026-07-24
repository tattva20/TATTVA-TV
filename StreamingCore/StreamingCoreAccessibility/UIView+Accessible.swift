import UIKit

public extension UIView {
	@discardableResult
	func accessible(_ spec: AccessibilitySpec = .default) -> Self {
		isAccessibilityElement = spec.isElement
		accessibilityLabel = spec.label
		accessibilityValue = spec.value
		accessibilityHint = spec.hint
		accessibilityTraits = spec.traits
		return self
	}

	@discardableResult
	func accessible(
		label: String? = nil,
		value: String? = nil,
		hint: String? = nil,
		traits: UIAccessibilityTraits = .none,
		isElement: Bool = true
	) -> Self {
		accessible(AccessibilitySpec(
			isElement: isElement, label: label, value: value, hint: hint, traits: traits
		))
	}
}
