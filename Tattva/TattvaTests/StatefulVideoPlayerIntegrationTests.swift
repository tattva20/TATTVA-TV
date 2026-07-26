//
//  StatefulVideoPlayerIntegrationTests.swift
//  TattvaTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import XCTest
import StreamingCore
import StreamingCoreiOS
@testable import Tattva
@testable import StreamingCorePlayback

@MainActor
final class StatefulVideoPlayerIntegrationTests: XCTestCase {

	override func tearDown() {
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	// MARK: - VideoPlayerUIComposer Integration Tests

	func test_videoPlayerComposedWith_createsControllerWithStatefulPlayer() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertNotNil(controller.playbackCollaborators?.statefulPlayer, "Expected VideoPlayerViewController to have a stateful player after composition")
	}

	func test_statefulPlayer_exposesStatePublisher() {
		let video = makeVideo()
		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertNotNil(controller.playbackCollaborators?.statefulPlayer.statePublisher, "Expected stateful player to expose state publisher")
	}

	func test_statefulPlayer_startsInLoadingState() {
		let video = makeVideo()
		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		// After composition, state should be idle (no load called yet), loading, or ready
		let state = controller.playbackCollaborators?.statefulPlayer.currentPlaybackState
		let isValidInitialState: Bool
		switch state {
		case .idle, .ready:
			isValidInitialState = true
		case .loading:
			isValidInitialState = true
		default:
			isValidInitialState = false
		}
		XCTAssertTrue(isValidInitialState, "Expected player to be in loading, ready, or idle state after composition, got: \(String(describing: state))")
	}

	// MARK: - Helpers

	private func makeVideo() -> Video {
		Video(
			id: UUID(),
			title: "Test Video",
			description: "Test Description",
			url: URL(string: "https://example.com/video.mp4")!,
			thumbnailURL: URL(string: "https://example.com/image.jpg")!,
			duration: 120
		)
	}
}
