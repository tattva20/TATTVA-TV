import UIKit
import StreamingCore

public final class TVVideoInfoViewController: UIViewController {
	private let video: Video

	public let titleLabel = UILabel()
	public let durationLabel = UILabel()
	public let descriptionLabel = UILabel()

	public init(video: Video) {
		self.video = video
		super.init(nibName: nil, bundle: nil)
		title = Self.tabTitle
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		configureViews()
	}

	private func configureViews() {
		titleLabel.text = video.title
		titleLabel.font = .preferredFont(forTextStyle: .title2)
		titleLabel.numberOfLines = 0

		durationLabel.text = Self.formattedDuration(video.duration)
		durationLabel.font = .preferredFont(forTextStyle: .caption1)
		durationLabel.textColor = .secondaryLabel
		durationLabel.isHidden = durationLabel.text == nil

		descriptionLabel.text = video.description
		descriptionLabel.font = .preferredFont(forTextStyle: .body)
		descriptionLabel.textColor = .secondaryLabel
		descriptionLabel.numberOfLines = 0

		let stack = UIStackView(arrangedSubviews: [titleLabel, durationLabel, descriptionLabel])
		stack.axis = .vertical
		stack.spacing = 12
		stack.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(stack)

		NSLayoutConstraint.activate([
			stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
			stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
			stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -60)
		])
	}

	static func formattedDuration(_ duration: TimeInterval) -> String? {
		guard duration > 0 else { return nil }
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad
		return formatter.string(from: duration)
	}
}

private extension TVVideoInfoViewController {
	static let tabTitle = "Info"
}
