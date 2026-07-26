import UIKit
import StreamingCore
import StreamingCoreAccessibility

public final class TVVideosViewController: UICollectionViewController {
	public var onRefresh: (() -> Void)?
	public var onLoadMore: (() -> Void)?
	public var onRetry: (() -> Void)?

	private(set) var errorMessage: String?
	private(set) var isLoadingIndicatorVisible = false
	private(set) var retryButton: UIButton?

	private lazy var dataSource: UICollectionViewDiffableDataSource<Int, TVCellController> = {
		UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, controller in
			controller.dataSource.collectionView(collectionView, cellForItemAt: indexPath)
		}
	}()

	public init() {
		super.init(collectionViewLayout: Self.makeLayout())
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		collectionView.register(TVVideoPosterCell.self, forCellWithReuseIdentifier: TVVideoPosterCell.reuseID)
		collectionView.dataSource = dataSource
		onRefresh?()
	}

	public func display(_ controllers: [TVCellController]) {
		var snapshot = NSDiffableDataSourceSnapshot<Int, TVCellController>()
		snapshot.appendSections([0])
		snapshot.appendItems(controllers, toSection: 0)
		dataSource.apply(snapshot, animatingDifferences: false)
	}

	public func display(isLoading: Bool) {
		isLoadingIndicatorVisible = isLoading
		if isLoading {
			let spinner = UIActivityIndicatorView(style: .large)
			spinner.startAnimating()
			collectionView.backgroundView = spinner
		} else if errorMessage == nil {
			collectionView.backgroundView = nil
		}
	}

	public func display(errorMessage message: String?) {
		errorMessage = message
		guard let message else {
			retryButton = nil
			if !isLoadingIndicatorVisible {
				collectionView.backgroundView = nil
			}
			return
		}
		collectionView.backgroundView = makeErrorView(message: message)
	}

	private func makeErrorView(message: String) -> UIView {
		let label = UILabel()
		label.text = message
		label.font = .preferredFont(forTextStyle: .title3)
		label.textColor = .secondaryLabel
		label.numberOfLines = 0
		label.textAlignment = .center

		let button = UIButton(type: .system)
		button.setTitle("Try Again", for: .normal)
		button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
		button.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .primaryActionTriggered)
		button.accessible(label: "Try Again", role: .button)
		retryButton = button

		let stack = UIStackView(arrangedSubviews: [label, button])
		stack.axis = .vertical
		stack.alignment = .center
		stack.spacing = 24
		return stack
	}

	public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let controller = dataSource.itemIdentifier(for: indexPath)
		controller?.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
	}

	public override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if indexPath.item == dataSource.snapshot().numberOfItems - 1 {
			onLoadMore?()
		}
	}

	public override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		let controller = dataSource.itemIdentifier(for: indexPath)
		controller?.delegate?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
	}

	private static func makeLayout() -> UICollectionViewLayout {
		let item = NSCollectionLayoutItem(
			layoutSize: NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(0.2),
				heightDimension: .fractionalHeight(1.0)))
		item.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

		let group = NSCollectionLayoutGroup.horizontal(
			layoutSize: NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(1.0),
				heightDimension: .absolute(400)),
			subitems: [item])

		let section = NSCollectionLayoutSection(group: group)
		section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 60, bottom: 40, trailing: 60)

		return UICollectionViewCompositionalLayout(section: section)
	}
}
