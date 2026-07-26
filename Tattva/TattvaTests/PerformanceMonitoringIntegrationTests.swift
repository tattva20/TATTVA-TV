//
//  PerformanceMonitoringIntegrationTests.swift
//  TattvaTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import Combine
import StreamingCore
import StreamingCoreiOS
@testable import Tattva
@testable import StreamingCorePlayback

@MainActor
final class PerformanceMonitoringIntegrationTests: XCTestCase {

	override func tearDown() {
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	// MARK: - VideoPlayerUIComposer Integration Tests

	func test_videoPlayerComposedWith_createsControllerWithPerformanceAdapter() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertNotNil(controller.playbackCollaborators?.performanceAdapter, "Expected VideoPlayerViewController to have a performance adapter after composition")
	}

	func test_videoPlayerComposedWith_startsPerformanceMonitoringOnCreation() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertTrue(controller.playbackCollaborators?.performanceAdapter.isObserving == true, "Expected performance monitoring to be started after composition")
	}

	func test_videoPlayerComposedWith_wiresBufferAdapter_whenBufferManagerProvided() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(
			video: video,
			bufferManager: AdaptiveBufferManager())

		XCTAssertNotNil(controller.playbackCollaborators?.bufferAdapter, "Expected a buffer adapter wired to the player when a buffer manager is provided")
	}

	func test_videoPlayerComposedWith_omitsBufferAdapter_whenNoBufferManager() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertNil(controller.playbackCollaborators?.bufferAdapter, "Expected no buffer adapter when no buffer manager is provided")
	}

	func test_videoPlayerComposedWith_wiresNetworkBitrateBinding() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertNotNil(controller.playbackCollaborators?.networkBitrateBinding, "Expected a network-driven bitrate binding wired after composition")
	}

	func test_videoPlayerComposedWith_wiresMemoryPerformanceBinding_whenPublisherProvided() {
		let subject = PassthroughSubject<MemoryState, Never>()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(
			video: makeVideo(),
			memoryStatePublisher: subject.eraseToAnyPublisher())

		XCTAssertNotNil(controller.playbackCollaborators?.memoryPerformanceCancellable, "Expected a memory-performance binding when a publisher is provided")
		subject.send(MemoryState(availableBytes: 100, totalBytes: 200, usedBytes: 100, timestamp: Date()))
		_ = controller
	}

	func test_videoPlayerComposedWith_omitsMemoryPerformanceBinding_whenNoPublisher() {
		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: makeVideo())

		XCTAssertNil(controller.playbackCollaborators?.memoryPerformanceCancellable, "Expected no memory-performance binding without a publisher")
	}

	func test_networkQualitySignal_isDeliveredToBufferManager() {
		let bufferManager = BufferManagerSpy()
		let expectation = expectation(description: "buffer manager receives a network-quality update")
		expectation.assertForOverFulfill = false
		bufferManager.onUpdateNetworkQuality = { _ in expectation.fulfill() }

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: makeVideo(), bufferManager: bufferManager)

		wait(for: [expectation], timeout: 2.0)
		XCTAssertFalse(
			bufferManager.receivedNetworkQualities.isEmpty,
			"Expected the composed network monitor to drive the buffer manager's network quality")
		_ = controller
	}

	func test_performanceAdapter_stopsMonitoringWhenControllerDeallocates() async {
		let video = makeVideo()
		weak var weakAdapter: VideoPlayerPerformanceAdapter?

		autoreleasepool {
			let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)
			weakAdapter = controller.playbackCollaborators?.performanceAdapter
			XCTAssertNotNil(weakAdapter)
		}

		await poll(until: { weakAdapter == nil })

		XCTAssertNil(weakAdapter, "Expected performance adapter to be deallocated when controller is deallocated")
	}

	func test_videoPlayerComposedWith_startsAndPersistsAnalyticsSession_whenAnalyticsLoggerProvided() async {
		let store = InMemoryAnalyticsStore()
		let analytics = PlaybackAnalyticsService(store: store)
		let video = makeVideo()

		_ = VideoPlayerUIComposer.videoPlayerComposedWith(video: video, analyticsLogger: analytics)

		var sessions: [LocalPlaybackSession] = []
		let deadline = Date() + 5
		while Date() < deadline {
			sessions = (try? await store.retrieveAllSessions()) ?? []
			if !sessions.isEmpty { break }
			try? await Task.sleep(nanoseconds: 10_000_000)
		}

		XCTAssertEqual(sessions.count, 1, "Expected composition to start and persist an analytics session")
		XCTAssertEqual(sessions.first?.videoID, video.id, "Expected the persisted session to reference the composed video")
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

	@MainActor
	private final class BufferManagerSpy: BufferManager {
		private(set) var receivedNetworkQualities: [NetworkQuality] = []
		private(set) var receivedMemoryStates: [MemoryState] = []
		var onUpdateNetworkQuality: ((NetworkQuality) -> Void)?

		private let subject = CurrentValueSubject<BufferConfiguration, Never>(.balanced)
		var currentConfiguration: BufferConfiguration { subject.value }
		var configurationPublisher: AnyPublisher<BufferConfiguration, Never> { subject.eraseToAnyPublisher() }

		func updateMemoryState(_ state: MemoryState) {
			receivedMemoryStates.append(state)
		}

		func updateNetworkQuality(_ quality: NetworkQuality) {
			receivedNetworkQualities.append(quality)
			onUpdateNetworkQuality?(quality)
		}
	}
}
