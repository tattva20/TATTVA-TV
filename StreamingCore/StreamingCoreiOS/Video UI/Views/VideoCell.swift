//
//  VideoCell.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreAccessibility

public final class VideoCell: UITableViewCell {
	private(set) public var titleLabel: UILabel!
	private(set) public var videoImageContainer: UIView!
	private(set) public var videoImageView: UIImageView!
	private(set) public var videoImageRetryButton: UIButton!
	private(set) public var descriptionLabel: UILabel!

	public var onRetry: (() -> Void)?
	public var onReuse: (() -> Void)?

	public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupViews()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupViews()
	}

	private func setupViews() {
		videoImageContainer = UIView()
		videoImageContainer.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(videoImageContainer)

		videoImageView = UIImageView()
		videoImageView.translatesAutoresizingMaskIntoConstraints = false
		videoImageView.contentMode = .scaleAspectFill
		videoImageView.clipsToBounds = true
		videoImageView.backgroundColor = .secondarySystemBackground
		videoImageContainer.addSubview(videoImageView)

		videoImageRetryButton = UIButton()
		videoImageRetryButton.translatesAutoresizingMaskIntoConstraints = false
		videoImageRetryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
		videoImageRetryButton.setTitle("↻", for: .normal)
		videoImageRetryButton.titleLabel?.font = .systemFont(ofSize: 60)
		videoImageRetryButton.setTitleColor(.white, for: .normal)
		videoImageRetryButton.accessible(label: "Retry", hint: "Reloads the video thumbnail", role: .button)
		videoImageRetryButton.layer.shadowOffset = CGSize(width: 0, height: 1)
		videoImageRetryButton.layer.shadowOpacity = 0.8
		videoImageRetryButton.layer.shadowRadius = 2
		videoImageContainer.addSubview(videoImageRetryButton)

		titleLabel = UILabel()
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.numberOfLines = 2
		titleLabel.font = .preferredFont(forTextStyle: .body)
		titleLabel.adjustsFontForContentSizeCategory = true
		contentView.addSubview(titleLabel)

		descriptionLabel = UILabel()
		descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
		descriptionLabel.numberOfLines = 3
		descriptionLabel.font = .preferredFont(forTextStyle: .footnote)
		descriptionLabel.textColor = .secondaryLabel
		descriptionLabel.adjustsFontForContentSizeCategory = true
		contentView.addSubview(descriptionLabel)

		NSLayoutConstraint.activate([
			// Video Image Container
			videoImageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
			videoImageContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
			videoImageContainer.widthAnchor.constraint(equalToConstant: 160),
			videoImageContainer.heightAnchor.constraint(equalToConstant: 90),

			// Video Image View
			videoImageView.leadingAnchor.constraint(equalTo: videoImageContainer.leadingAnchor),
			videoImageView.topAnchor.constraint(equalTo: videoImageContainer.topAnchor),
			videoImageView.trailingAnchor.constraint(equalTo: videoImageContainer.trailingAnchor),
			videoImageView.bottomAnchor.constraint(equalTo: videoImageContainer.bottomAnchor),

			// Retry Button
			videoImageRetryButton.centerXAnchor.constraint(equalTo: videoImageContainer.centerXAnchor),
			videoImageRetryButton.centerYAnchor.constraint(equalTo: videoImageContainer.centerYAnchor),

			// Title Label
			titleLabel.leadingAnchor.constraint(equalTo: videoImageContainer.trailingAnchor, constant: 8),
			titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
			titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

			// Description Label
			descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
			descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
			descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
			descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),

			// Content View Height
			contentView.bottomAnchor.constraint(greaterThanOrEqualTo: videoImageContainer.bottomAnchor, constant: 8)
		])
	}

	@objc private func retryButtonTapped() {
		onRetry?()
	}

	public override func prepareForReuse() {
		super.prepareForReuse()

		onReuse?()
	}
}