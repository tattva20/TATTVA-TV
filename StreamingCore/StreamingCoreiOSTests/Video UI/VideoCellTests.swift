//
//  VideoCellTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCoreiOS

@MainActor
final class VideoCellTests: XCTestCase {

	func test_retryButton_hasAccessibleLabelInsteadOfGlyphTitle() {
		let sut = makeSUT()

		XCTAssertEqual(
			sut.videoImageRetryButton.accessibilityLabel,
			"Retry",
			"Expected a spoken label so VoiceOver does not read the raw glyph title")
		XCTAssertTrue(sut.videoImageRetryButton.accessibilityTraits.contains(.button))
	}

	// MARK: - Helpers

	private func makeSUT() -> VideoCell {
		VideoCell(style: .default, reuseIdentifier: nil)
	}
}
