//
//  CommentsEmbeddingControllerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import UIKit
import StreamingCoreiOS

@MainActor
final class CommentsEmbeddingControllerTests: XCTestCase {

	func test_init_isNotEmbedded() {
		let (sut, _, _, _) = makeSUT()

		XCTAssertFalse(sut.isEmbedded)
	}

	func test_embed_addsTaggedContainerToParentViewAndBecomesEmbedded() {
		let (sut, parent, child, anchor) = makeSUT()

		sut.embed(child, in: parent, below: anchor, isLandscape: false)

		XCTAssertTrue(sut.isEmbedded)
		XCTAssertNotNil(parent.view.viewWithTag(999), "Expected a tagged comments container in the parent view")
	}

	func test_embed_addsControllerAsChildOfParent() {
		let (sut, parent, child, anchor) = makeSUT()

		sut.embed(child, in: parent, below: anchor, isLandscape: false)

		XCTAssertTrue(parent.children.contains(child), "Expected the comments controller to be a child of the parent")
		XCTAssertEqual(child.parent, parent)
	}

	func test_embed_isNoOpWhenAlreadyEmbedded() {
		let (sut, parent, child, anchor) = makeSUT()
		sut.embed(child, in: parent, below: anchor, isLandscape: false)

		let second = UIViewController()
		sut.embed(second, in: parent, below: anchor, isLandscape: false)

		XCTAssertFalse(parent.children.contains(second), "Expected a second embed to be ignored")
		XCTAssertEqual(parent.children.count, 1)
	}

	func test_setVisible_false_hidesContainer() {
		let (sut, parent, child, anchor) = makeSUT()
		sut.embed(child, in: parent, below: anchor, isLandscape: false)

		sut.setVisible(false)

		XCTAssertTrue(parent.view.viewWithTag(999)?.isHidden ?? false)
	}

	func test_setVisible_true_showsContainer() {
		let (sut, parent, child, anchor) = makeSUT()
		sut.embed(child, in: parent, below: anchor, isLandscape: false)
		sut.setVisible(false)

		sut.setVisible(true)

		XCTAssertFalse(parent.view.viewWithTag(999)?.isHidden ?? true)
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: CommentsEmbeddingController, parent: UIViewController, child: UIViewController, anchor: UIView) {
		let sut = CommentsEmbeddingController()
		let parent = UIViewController()
		parent.loadViewIfNeeded()
		let anchor = UIView()
		anchor.translatesAutoresizingMaskIntoConstraints = false
		parent.view.addSubview(anchor)
		let child = UIViewController()
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, parent, child, anchor)
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}
}
