import XCTest
import UIKit
import StreamingCore
@testable import TattvaTV

@MainActor
final class TVCommentsViewControllerTests: XCTestCase {
	override func tearDown() {
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	func test_onAppearance_rendersCommentsFromLoader() async {
		let comments = [
			makeComment(message: "First message", username: "alice"),
			makeComment(message: "Second message", username: "bob")
		]
		let sut = makeSUT(comments: comments)

		sut.simulateAppearance()

		await eventually { sut.numberOfRenderedComments() == 2 }
		XCTAssertEqual(sut.commentMessage(at: 0), "First message")
		XCTAssertEqual(sut.commentUsername(at: 0), "alice")
		XCTAssertEqual(sut.commentMessage(at: 1), "Second message")
		XCTAssertEqual(sut.commentUsername(at: 1), "bob")
	}

	func test_emptyComments_showsEmptyMessage() async {
		let sut = makeSUT(comments: [])

		sut.simulateAppearance()

		await eventually { sut.messageText() != nil }
		XCTAssertEqual(sut.messageText(), "No comments yet")
		XCTAssertEqual(sut.numberOfRenderedComments(), 0)
	}

	func test_loadFailure_showsErrorMessage() async {
		let sut = TVCommentsUIComposer.commentsComposedWith(commentsLoader: { throw AnyError() })

		sut.simulateAppearance()

		await eventually { sut.messageText() != nil }
		XCTAssertNotNil(sut.messageText(), "Expected an error message when comments loading fails")
		XCTAssertNotEqual(sut.messageText(), "No comments yet", "Expected the error message, not the empty message")
	}

	func test_hasCommentsTitle_soTheInfoPanelTabReadsCommentsNotApplication() {
		let sut = makeSUT(comments: [])

		XCTAssertEqual(sut.title, "Comments")
	}

	// MARK: - Helpers

	private func makeSUT(comments: [VideoComment]) -> TVCommentsViewController {
		TVCommentsUIComposer.commentsComposedWith(commentsLoader: { comments })
	}

	private struct AnyError: Error {}
	private func anyError() -> Error { AnyError() }

	private func eventually(_ condition: () -> Bool, iterations: Int = 100) async {
		for _ in 0..<iterations {
			if condition() { return }
			await Task.yield()
		}
	}

	private func makeComment(message: String, username: String) -> VideoComment {
		VideoComment(id: UUID(), message: message, createdAt: Date(), username: username)
	}
}

@MainActor
extension TVCommentsViewController {
	func simulateAppearance() {
		loadViewIfNeeded()
		collectionView.frame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
		collectionView.layoutIfNeeded()
	}

	func numberOfRenderedComments() -> Int {
		collectionView.numberOfItems(inSection: 0)
	}

	private func commentCell(at index: Int) -> TVCommentCell? {
		let indexPath = IndexPath(item: index, section: 0)
		return collectionView.dataSource?.collectionView(collectionView, cellForItemAt: indexPath) as? TVCommentCell
	}

	func commentMessage(at index: Int) -> String? {
		commentCell(at: index)?.messageText
	}

	func commentUsername(at index: Int) -> String? {
		commentCell(at: index)?.usernameText
	}

	func messageText() -> String? {
		view.subviews.compactMap { $0 as? UILabel }.first(where: { $0.text?.isEmpty == false })?.text
	}
}
