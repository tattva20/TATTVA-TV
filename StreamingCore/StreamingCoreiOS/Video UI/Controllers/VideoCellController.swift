//
//  VideoCellController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreAccessibility

public protocol VideoCellControllerDelegate {
	func didRequestImage()
	func didCancelImageRequest()
}

@MainActor
public final class VideoCellController: NSObject {
	public typealias ResourceViewModel = UIImage

	private let viewModel: VideoViewModel
	private let delegate: VideoCellControllerDelegate
	private let selection: () -> Void
	private var cell: VideoCell?

	public init(viewModel: VideoViewModel, delegate: VideoCellControllerDelegate, selection: @escaping () -> Void) {
		self.viewModel = viewModel
		self.delegate = delegate
		self.selection = selection
	}
}

extension VideoCellController: UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		1
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		cell = tableView.dequeueReusableCell()
		cell?.titleLabel.text = viewModel.title
		cell?.descriptionLabel.text = viewModel.description
		cell?.accessible(
			label: [viewModel.title, viewModel.description].compactMap { $0 }.joined(separator: ". "),
			role: .button)
		cell?.videoImageView.image = nil
		cell?.videoImageContainer.isShimmering = true
		cell?.videoImageRetryButton.isHidden = true
		cell?.onRetry = { [weak self] in
			self?.delegate.didRequestImage()
		}
		cell?.onReuse = { [weak self] in
			self?.releaseCellForReuse()
		}
		delegate.didRequestImage()
		return cell!
	}

	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		selection()
	}

	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		self.cell = cell as? VideoCell
		delegate.didRequestImage()
	}

	public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cancelLoad()
	}

	public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
		delegate.didRequestImage()
	}

	public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
		cancelLoad()
	}

	private func cancelLoad() {
		releaseCellForReuse()
		delegate.didCancelImageRequest()
	}

	private func releaseCellForReuse() {
		cell?.onReuse = nil
		cell = nil
	}
}

extension VideoCellController: ResourceView, ResourceLoadingView, ResourceErrorView {
	public func display(_ viewModel: UIImage) {
		cell?.videoImageView.setImageAnimated(viewModel)
	}

	public func display(_ viewModel: ResourceLoadingViewModel) {
		cell?.videoImageContainer.isShimmering = viewModel.isLoading
	}

	public func display(_ viewModel: ResourceErrorViewModel) {
		cell?.videoImageRetryButton.isHidden = viewModel.message == nil
	}
}