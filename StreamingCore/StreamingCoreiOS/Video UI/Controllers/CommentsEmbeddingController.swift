//
//  CommentsEmbeddingController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit

@MainActor
public final class CommentsEmbeddingController {
	private var container: UIView?
	private var containerConstraints: [NSLayoutConstraint] = []

	public init() {}

	public var isEmbedded: Bool { container != nil }

	public func embed(_ controller: UIViewController, in parent: UIViewController, below topAnchorView: UIView, isLandscape: Bool) {
		guard container == nil else { return }

		let containerView = UIView()
		containerView.translatesAutoresizingMaskIntoConstraints = false
		containerView.backgroundColor = .systemBackground
		containerView.tag = 999
		parent.view.addSubview(containerView)
		container = containerView

		parent.addChild(controller)
		controller.view.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(controller.view)
		controller.didMove(toParent: parent)

		containerConstraints = [
			containerView.topAnchor.constraint(equalTo: topAnchorView.bottomAnchor, constant: 16),
			containerView.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
			containerView.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
			containerView.bottomAnchor.constraint(equalTo: parent.view.safeAreaLayoutGuide.bottomAnchor),
			controller.view.topAnchor.constraint(equalTo: containerView.topAnchor),
			controller.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
			controller.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
			controller.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
		]

		if !isLandscape {
			NSLayoutConstraint.activate(containerConstraints)
		}
	}

	public func setVisible(_ visible: Bool) {
		container?.isHidden = !visible
		if visible {
			NSLayoutConstraint.activate(containerConstraints)
		} else {
			NSLayoutConstraint.deactivate(containerConstraints)
		}
	}
}
