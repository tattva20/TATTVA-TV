//
//  VideoCommentCellControllerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore
import StreamingCoreiOS

@MainActor
final class VideoCommentCellControllerTests: XCTestCase {

	func test_tableViewDataSource_returnsOneRow() {
		let sut = makeSUT()

		let numberOfRows = sut.tableView(UITableView(), numberOfRowsInSection: 0)

		XCTAssertEqual(numberOfRows, 1)
	}

	func test_cellForRowAtIndexPath_returnsVideoCommentCell() {
		let sut = makeSUT()
		let tableView = makeTableView()

		let cell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))

		XCTAssertTrue(cell is VideoCommentCell)
	}

	func test_cellForRowAtIndexPath_configuresCellWithMessage() {
		let model = makeViewModel(message: "a message")
		let sut = makeSUT(model: model)
		let tableView = makeTableView()

		let cell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? VideoCommentCell

		XCTAssertEqual(cell?.messageLabel.text, "a message")
	}

	func test_cellForRowAtIndexPath_configuresCellWithUsername() {
		let model = makeViewModel(username: "a username")
		let sut = makeSUT(model: model)
		let tableView = makeTableView()

		let cell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? VideoCommentCell

		XCTAssertEqual(cell?.usernameLabel.text, "a username")
	}

	func test_cellForRowAtIndexPath_configuresCellWithDate() {
		let model = makeViewModel(date: "2 days ago")
		let sut = makeSUT(model: model)
		let tableView = makeTableView()

		let cell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? VideoCommentCell

		XCTAssertEqual(cell?.dateLabel.text, "2 days ago")
	}

	func test_cellForRowAtIndexPath_exposesCommentAsSingleAccessibilityElement() {
		let model = makeViewModel(message: "Nice video", date: "2 days ago", username: "Jane")
		let sut = makeSUT(model: model)
		let tableView = makeTableView()

		let cell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? VideoCommentCell

		XCTAssertEqual(cell?.isAccessibilityElement, true, "The comment cell should be a single VoiceOver element")
		XCTAssertEqual(cell?.accessibilityLabel, "Jane. Nice video. 2 days ago")
	}

	// MARK: - Helpers

	private func makeSUT(model: VideoCommentViewModel? = nil) -> VideoCommentCellController {
		VideoCommentCellController(model: model ?? makeViewModel())
	}

	private func makeViewModel(
		message: String = "any message",
		date: String = "any date",
		username: String = "any username"
	) -> VideoCommentViewModel {
		VideoCommentViewModel(message: message, date: date, username: username)
	}

	private func makeTableView() -> UITableView {
		let tableView = UITableView()
		tableView.register(VideoCommentCell.self, forCellReuseIdentifier: String(describing: VideoCommentCell.self))
		return tableView
	}
}
