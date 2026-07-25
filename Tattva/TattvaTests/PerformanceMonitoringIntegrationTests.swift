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

		XCTAssertNotNil(controller.performanceAdapter, "Expected VideoPlayerViewController to have a performance adapter after composition")
	}

	func test_videoPlayerComposedWith_startsPerformanceMonitoringOnCreation() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertTrue(controller.performanceAdapter?.isObserving == true, "Expected performance monitoring to be started after composition")
	}

	func test_videoPlayerComposedWith_wiresBufferAdapter_whenBufferManagerProvided() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(
			video: video,
			bufferManager: AdaptiveBufferManager())

		XCTAssertNotNil(controller.bufferAdapter, "Expected a buffer adapter wired to the player when a buffer manager is provided")
	}

	func test_videoPlayerComposedWith_omitsBufferAdapter_whenNoBufferManager() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertNil(controller.bufferAdapter, "Expected no buffer adapter when no buffer manager is provided")
	}

	func test_videoPlayerComposedWith_wiresNetworkBitrateBinding() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertNotNil(controller.networkBitrateBinding, "Expected a network-driven bitrate binding wired after composition")
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
			weakAdapter = controller.performanceAdapter
			XCTAssertNotNil(weakAdapter)
		}

		await poll(until: { weakAdapter == nil })

		XCTAssertNil(weakAdapter, "Expected performance adapter to be deallocated when controller is deallocated")
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
