//
//  VideoCommentCellController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreAccessibility

public class VideoCommentCellController: NSObject, UITableViewDataSource {
	private let model: VideoCommentViewModel

	public init(model: VideoCommentViewModel) {
		self.model = model
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		1
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: VideoCommentCell = tableView.dequeueReusableCell()
		cell.messageLabel.text = model.message
		cell.usernameLabel.text = model.username
		cell.dateLabel.text = model.date
		cell.accessible(
			label: [model.username, model.message, model.date].joined(separator: ". "),
			role: .staticText)
		return cell
	}
}
