import UIKit
import StreamingCore

public protocol Announcer {
	func announce(_ message: String)
}

public final class UIKitAnnouncer: Announcer {
	public init() {}

	public func announce(_ message: String) {
		UIAccessibility.post(notification: .announcement, argument: message)
	}
}

public final class AnnouncingResourceView<Decoratee: ResourceView>: ResourceView {
	public typealias ResourceViewModel = Decoratee.ResourceViewModel

	private let decoratee: Decoratee
	private let announcer: Announcer
	private let describe: (ResourceViewModel) -> String?

	public init(
		decoratee: Decoratee,
		announcer: Announcer,
		describe: @escaping (ResourceViewModel) -> String?
	) {
		self.decoratee = decoratee
		self.announcer = announcer
		self.describe = describe
	}

	public func display(_ viewModel: ResourceViewModel) {
		decoratee.display(viewModel)
		if let message = describe(viewModel) {
			announcer.announce(message)
		}
	}
}
