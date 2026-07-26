//
//  ProductionIntegrationTests.swift
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
final class ProductionIntegrationTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
		RunLoop.current.run(until: Date())
	}

	// MARK: - Full Stack Component Initialization Tests

	func test_sceneDelegate_initializesAllComponents() {
		let sut = SceneDelegate()

		// Core components
		XCTAssertNotNil(sut.memoryMonitor, "Expected memory monitor to be initialized")
		XCTAssertNotNil(sut.resourceCleanupCoordinator, "Expected resource cleanup coordinator to be initialized")
		XCTAssertNotNil(sut.bufferManager, "Expected buffer manager to be initialized")
	}

	func test_sceneDelegate_enablesAutoCleanupOnConfigureWindow() {
		let sut = SceneDelegate()

		XCTAssertFalse(sut.isAutoCleanupEnabled, "Expected auto cleanup to be disabled initially")

		sut.configureWindow()

		XCTAssertTrue(sut.isAutoCleanupEnabled, "Expected auto cleanup to be enabled after configureWindow")
	}

	// MARK: - VideoPlayer Composition Tests

	func test_videoPlayerComposition_createsFullyDecoratedPlayer() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		// Should have stateful player wrapper
		XCTAssertNotNil(controller.playbackCollaborators?.statefulPlayer, "Expected controller to have stateful player")

		// Should have state publisher
		XCTAssertNotNil(controller.playbackCollaborators?.statefulPlayer.statePublisher, "Expected stateful player to have state publisher")
	}

	func test_videoPlayerComposition_startsInValidInitialState() {
		let video = makeVideo()
		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		let state = controller.playbackCollaborators?.statefulPlayer.currentPlaybackState
		let isValidState: Bool
		switch state {
		case .idle, .loading, .ready:
			isValidState = true
		default:
			isValidState = false
		}

		XCTAssertTrue(isValidState, "Expected player to start in a valid initial state (idle, loading, or ready), got: \(String(describing: state))")
	}

	// MARK: - Component Integration Tests

	func test_bufferManager_startsWithDefaultConfiguration() {
		let sut = SceneDelegate()

		XCTAssertEqual(sut.bufferManager.currentConfiguration.strategy, .balanced, "Expected buffer manager to start with balanced strategy")
	}

	func test_memoryMonitor_canRetrieveCurrentState() async {
		let sut = SceneDelegate()

		let state = sut.memoryMonitor.currentMemoryState()

		XCTAssertGreaterThan(state.totalBytes, 0, "Expected memory state to have valid total bytes")
	}

	// MARK: - Resource Cleanup Coordination Tests

	func test_resourceCleanupCoordinator_isConfiguredWithCleaners() {
		let sut = SceneDelegate()

		// The coordinator should be properly configured and not crash when accessed
		XCTAssertNotNil(sut.resourceCleanupCoordinator, "Expected resource cleanup coordinator to be properly configured")
	}

	// MARK: - Helpers

	private func makeVideo() -> Video {
		Video(
			id: UUID(),
			title: "Integration Test Video",
			description: "A video for integration testing",
			url: URL(string: "https://example.com/video.mp4")!,
			thumbnailURL: URL(string: "https://example.com/thumbnail.jpg")!,
			duration: 180
		)
	}
}
