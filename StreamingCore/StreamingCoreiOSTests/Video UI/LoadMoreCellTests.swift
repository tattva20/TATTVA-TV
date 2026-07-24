//
//  LoadMoreCellTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCoreiOS

@MainActor
class LoadMoreCellTests: XCTestCase {

    func test_init_rendersNoLoadingIndicatorOrMessage() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isLoading, "Expected no loading indicator on init")
        XCTAssertNil(sut.message, "Expected no message on init")
    }

    func test_startLoading_displaysLoadingIndicator() {
        let sut = makeSUT()

        sut.isLoading = true

        XCTAssertTrue(sut.isLoading, "Expected loading indicator when loading starts")
    }

    func test_stopLoading_hidesLoadingIndicator() {
        let sut = makeSUT()

        sut.isLoading = true
        sut.isLoading = false

        XCTAssertFalse(sut.isLoading, "Expected no loading indicator when loading stops")
    }

    func test_setMessage_displaysMessage() {
        let sut = makeSUT()
        let message = "any message"

        sut.message = message

        XCTAssertEqual(sut.message, message, "Expected to display message")
    }

    func test_setNilMessage_hidesMessage() {
        let sut = makeSUT()

        sut.message = "any message"
        sut.message = nil

        XCTAssertNil(sut.message, "Expected to hide message")
    }

    func test_loading_announcesLoadingStateToVoiceOver() {
        let sut = makeSUT()

        sut.isLoading = true

        XCTAssertTrue(sut.isAccessibilityElement, "Expected the loading cell to be a VoiceOver element")
        XCTAssertEqual(sut.accessibilityLabel, "Loading more videos")
    }

    func test_errorMessage_exposesRetryButtonToVoiceOver() {
        let sut = makeSUT()

        sut.message = "Couldn't load more"

        XCTAssertTrue(sut.isAccessibilityElement, "Expected the error cell to be a VoiceOver element")
        XCTAssertEqual(sut.accessibilityLabel, "Couldn't load more")
        XCTAssertTrue(sut.accessibilityTraits.contains(.button), "Expected the retryable cell to be a button")
    }

    func test_idle_isNotAVoiceOverElement() {
        let sut = makeSUT()

        sut.isLoading = true
        sut.isLoading = false

        XCTAssertFalse(sut.isAccessibilityElement, "Expected an idle load-more cell to be skipped by VoiceOver")
    }

    // MARK: - Helpers

    private func makeSUT() -> LoadMoreCell {
        return LoadMoreCell()
    }
}
