import UIKit

public struct AccessibilitySpec: Sendable {
	public var isElement: Bool
	public var label: String?
	public var value: String?
	public var hint: String?
	public var traits: UIAccessibilityTraits

	public init(
		isElement: Bool = true,
		label: String? = nil,
		value: String? = nil,
		hint: String? = nil,
		traits: UIAccessibilityTraits = .none
	) {
		self.isElement = isElement
		self.label = label
		self.value = value
		self.hint = hint
		self.traits = traits
	}

	public static let `default` = AccessibilitySpec()
}
