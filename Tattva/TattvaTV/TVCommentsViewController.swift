import UIKit
import StreamingCore

public final class TVCommentsViewController: UICollectionViewController {
	public var onRefresh: (() -> Void)?

	private let loadingIndicator = UIActivityIndicatorView(style: .large)
	private let messageLabel = UILabel()

	private lazy var dataSource = UICollectionViewDiffableDataSource<Int, VideoCommentViewModel>(collectionView: collectionView) { collectionView, indexPath, viewModel in
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TVCommentCell.reuseID, for: indexPath) as! TVCommentCell
		cell.configure(with: viewModel)
		return cell
	}

	public init() {
		super.init(collectionViewLayout: Self.makeLayout())
		title = Self.tabTitle
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		collectionView.register(TVCommentCell.self, forCellWithReuseIdentifier: TVCommentCell.reuseID)
		collectionView.dataSource = dataSource
		configureOverlays()
		onRefresh?()
	}

	private func configureOverlays() {
		loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
		loadingIndicator.hidesWhenStopped = true
		messageLabel.translatesAutoresizingMaskIntoConstraints = false
		messageLabel.font = .preferredFont(forTextStyle: .title3)
		messageLabel.textColor = .secondaryLabel
		messageLabel.textAlignment = .center
		messageLabel.numberOfLines = 0

		view.addSubview(loadingIndicator)
		view.addSubview(messageLabel)
		NSLayoutConstraint.activate([
			loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 80),
			messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -80)
		])
	}

	private static func makeLayout() -> UICollectionViewLayout {
		let item = NSCollectionLayoutItem(
			layoutSize: NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(1.0),
				heightDimension: .estimated(120)))

		let group = NSCollectionLayoutGroup.vertical(
			layoutSize: NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(1.0),
				heightDimension: .estimated(120)),
			subitems: [item])

		let section = NSCollectionLayoutSection(group: group)
		section.interGroupSpacing = 8
		section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 60, bottom: 40, trailing: 60)

		return UICollectionViewCompositionalLayout(section: section)
	}
}

extension TVCommentsViewController: ResourceView {
	public typealias ResourceViewModel = VideoCommentsViewModel

	public func display(_ viewModel: VideoCommentsViewModel) {
		var snapshot = NSDiffableDataSourceSnapshot<Int, VideoCommentViewModel>()
		snapshot.appendSections([0])
		snapshot.appendItems(viewModel.comments, toSection: 0)
		dataSource.apply(snapshot, animatingDifferences: false)

		messageLabel.text = viewModel.comments.isEmpty ? Self.emptyMessage : nil
	}
}

extension TVCommentsViewController: ResourceLoadingView {
	public func display(_ viewModel: ResourceLoadingViewModel) {
		if viewModel.isLoading {
			loadingIndicator.startAnimating()
		} else {
			loadingIndicator.stopAnimating()
		}
	}
}

extension TVCommentsViewController: ResourceErrorView {
	public func display(_ viewModel: ResourceErrorViewModel) {
		if let message = viewModel.message {
			messageLabel.text = message
		}
	}
}

private extension TVCommentsViewController {
	static let emptyMessage = "No comments yet"
	static let tabTitle = "Comments"
}
