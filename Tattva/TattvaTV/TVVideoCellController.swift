import UIKit
import StreamingCore

public final class TVVideoCellController: NSObject {
	private let viewModel: VideoViewModel
	private let imageLoader: (@Sendable (URL) async throws -> Data)?
	private let thumbnailURL: URL?
	private let selection: @MainActor () -> Void
	private var imageTask: Task<Void, Never>?

	public init(
		viewModel: VideoViewModel,
		imageLoader: (@Sendable (URL) async throws -> Data)? = nil,
		thumbnailURL: URL? = nil,
		selection: @escaping @MainActor () -> Void
	) {
		self.viewModel = viewModel
		self.imageLoader = imageLoader
		self.thumbnailURL = thumbnailURL
		self.selection = selection
	}
}

extension TVVideoCellController: UICollectionViewDataSource, UICollectionViewDelegate {
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		1
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TVVideoPosterCell.reuseID, for: indexPath) as! TVVideoPosterCell
		cell.configure(title: viewModel.title)
		requestImage(into: cell)
		return cell
	}

	public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		cancelImageRequest()
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selection()
	}

	private func requestImage(into cell: TVVideoPosterCell) {
		guard let imageLoader, let thumbnailURL else { return }
		imageTask?.cancel()
		imageTask = Task.immediate { @MainActor [weak cell] in
			guard let data = try? await imageLoader(thumbnailURL), !Task.isCancelled else { return }
			cell?.posterImageView.image = UIImage(data: data)
		}
	}

	private func cancelImageRequest() {
		imageTask?.cancel()
		imageTask = nil
	}
}
