//
//  LoadMoreCell.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreAccessibility

public class LoadMoreCell: UITableViewCell {

	private lazy var spinner: UIActivityIndicatorView = {
		let spinner = UIActivityIndicatorView(style: .medium)
		contentView.addSubview(spinner)

		spinner.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
			spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
			contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
		])

		return spinner
	}()

	private lazy var messageLabel: UILabel = {
		let label = UILabel()
		label.textColor = .tertiaryLabel
		label.font = .preferredFont(forTextStyle: .footnote)
		label.numberOfLines = 0
		label.textAlignment = .center
		label.adjustsFontForContentSizeCategory = true
		contentView.addSubview(label)

		label.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
			contentView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
			label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
			contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
		])

		return label
	}()

	public var isLoading: Bool {
		get { spinner.isAnimating }
		set {
			if newValue {
				spinner.startAnimating()
			} else {
				spinner.stopAnimating()
			}
			updateAccessibility()
		}
	}

	public var message: String? {
		get { messageLabel.text }
		set {
			messageLabel.text = newValue
			updateAccessibility()
		}
	}

	private func updateAccessibility() {
		if isLoading {
			accessible(label: "Loading more videos", role: .none)
		} else if let message = messageLabel.text, !message.isEmpty {
			accessible(label: message, hint: "Retries loading more videos", role: .button)
		} else {
			isAccessibilityElement = false
		}
	}

}