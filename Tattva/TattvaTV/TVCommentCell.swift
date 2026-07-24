import UIKit
import StreamingCore

public final class TVCommentCell: UICollectionViewCell {
	static let reuseID = "TVCommentCell"

	public let usernameLabel = UILabel()
	public let dateLabel = UILabel()
	public let messageLabel = UILabel()

	public var messageText: String? { messageLabel.text }
	public var usernameText: String? { usernameLabel.text }

	public override init(frame: CGRect) {
		super.init(frame: frame)
		configureViews()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func configure(with viewModel: VideoCommentViewModel) {
		usernameLabel.text = viewModel.username
		dateLabel.text = viewModel.date
		messageLabel.text = viewModel.message
		accessibilityLabel = [viewModel.username, viewModel.message, viewModel.date]
			.filter { !$0.isEmpty }
			.joined(separator: ". ")
	}

	private func configureViews() {
		isAccessibilityElement = true

		usernameLabel.font = .preferredFont(forTextStyle: .headline)
		usernameLabel.textColor = .label
		dateLabel.font = .preferredFont(forTextStyle: .caption1)
		dateLabel.textColor = .secondaryLabel
		messageLabel.font = .preferredFont(forTextStyle: .body)
		messageLabel.textColor = .label
		messageLabel.numberOfLines = 0

		let header = UIStackView(arrangedSubviews: [usernameLabel, dateLabel])
		header.axis = .horizontal
		header.spacing = 16
		header.alignment = .firstBaseline

		let stack = UIStackView(arrangedSubviews: [header, messageLabel])
		stack.axis = .vertical
		stack.spacing = 6
		stack.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(stack)

		NSLayoutConstraint.activate([
			stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
			stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
			stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
		])
	}
}
