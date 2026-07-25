//
//  PictureInPictureControllerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import AVKit
@testable import StreamingCoreiOS

@MainActor
final class PictureInPictureControllerTests: XCTestCase {

	func test_init_doesNotStartPictureInPicture() {
		let sut = makeSUT()

		XCTAssertFalse(sut.isPictureInPictureActive)
	}

	func test_isPictureInPicturePossible_returnsFalseWhenNotSetup() {
		let sut = makeSUT()

		XCTAssertFalse(sut.isPictureInPicturePossible)
	}

	func test_togglePictureInPicture_doesNothingWhenNotSetup() {
		let sut = makeSUT()

		// Should not crash when called without setup
		sut.togglePictureInPicture()

		XCTAssertFalse(sut.isPictureInPictureActive)
	}

	func test_startPictureInPicture_doesNothingWhenNotSetup() {
		let sut = makeSUT()

		// Should not crash when called without setup
		sut.startPictureInPicture()

		XCTAssertFalse(sut.isPictureInPictureActive)
	}

	func test_stopPictureInPicture_doesNothingWhenNotSetup() {
		let sut = makeSUT()

		// Should not crash when called without setup
		sut.stopPictureInPicture()

		XCTAssertFalse(sut.isPictureInPictureActive)
	}

	func test_restoreUserInterface_withoutHandler_completesTrue() {
		let sut = makeSUT()

		var restored: Bool?
		sut.restoreUserInterface { restored = $0 }

		XCTAssertEqual(restored, true, "Expected the default restore to complete successfully")
	}

	func test_restoreUserInterface_withHandler_invokesItAndForwardsResult() {
		let sut = makeSUT()
		var handlerReceivedCompletion = false
		sut.onRestoreUserInterface = { completion in
			handlerReceivedCompletion = true
			completion(false)
		}

		var restored: Bool?
		sut.restoreUserInterface { restored = $0 }

		XCTAssertTrue(handlerReceivedCompletion, "Expected the assigned restore handler to run")
		XCTAssertEqual(restored, false, "Expected the handler's completion result to be forwarded")
	}

	// MARK: - Helpers

	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> PictureInPictureController {
		let sut = PictureInPictureController()
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}
}
