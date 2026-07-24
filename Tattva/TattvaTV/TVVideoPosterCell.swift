import UIKit

public final class TVVideoPosterCell: UICollectionViewCell {
	static let reuseID = "TVVideoPosterCell"

	public let posterImageView = UIImageView()
	public let titleLabel = UILabel()

	public var titleText: String? { titleLabel.text }

	public override init(frame: CGRect) {
		super.init(frame: frame)
		configureViews()
	}

	public func configure(title: String?) {
		titleLabel.text = title
		accessibilityLabel = title
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override var canBecomeFocused: Bool { true }

	public override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		coordinator.addCoordinatedAnimations({ [weak self] in
			let scale: CGFloat = self?.isFocused == true ? 1.08 : 1.0
			self?.transform = CGAffineTransform(scaleX: scale, y: scale)
			self?.posterImageView.layer.borderWidth = self?.isFocused == true ? 4 : 0
		})
	}

	private func configureViews() {
		isAccessibilityElement = true
		accessibilityTraits = .button

		posterImageView.translatesAutoresizingMaskIntoConstraints = false
		posterImageView.contentMode = .scaleAspectFill
		posterImageView.clipsToBounds = true
		posterImageView.layer.cornerRadius = 8
		posterImageView.backgroundColor = UIColor(white: 0.18, alpha: 1.0)
		posterImageView.layer.borderColor = UIColor.white.cgColor

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.font = .preferredFont(forTextStyle: .caption1)
		titleLabel.textColor = .label
		titleLabel.numberOfLines = 1

		contentView.addSubview(posterImageView)
		contentView.addSubview(titleLabel)

		NSLayoutConstraint.activate([
			posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
			posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

			titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 8),
			titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
		])
	}

	public override func prepareForReuse() {
		super.prepareForReuse()
		posterImageView.image = nil
		titleLabel.text = nil
		accessibilityLabel = nil
	}
}
