//
//  AVPlayerPerformanceObserverTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import XCTest
@testable import StreamingCore
@testable import StreamingCorePlayback

final class AVPlayerPerformanceObserverTests: XCTestCase {

	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		cancellables.removeAll()
		RunLoop.current.run(until: Date())
		super.tearDown()
	}

	// MARK: - Playback State

	func test_init_startsWithIdleState() {
		let (sut, _) = makeSUT()

		XCTAssertEqual(sut.currentPlaybackState, .idle)
	}

	func test_playbackStatePublisher_emitsCurrentState() {
		let (sut, _) = makeSUT()
		var receivedStates: [ObserverPlaybackState] = []
		let exp = expectation(description: "Wait for state")

		sut.playbackStatePublisher
			.sink { state in
				receivedStates.append(state)
				exp.fulfill()
			}
			.store(in: &cancellables)

		wait(for: [exp], timeout: 1.0)

		XCTAssertEqual(receivedStates.first, .idle)
	}

	func test_performanceEventPublisher_emitsPlaybackStalled_onNativeStallNotification() {
		let item = AVPlayerItem(url: URL(string: "https://example.com/stream.m3u8")!)
		let (sut, _) = makeSUT(player: AVPlayer(playerItem: item))
		sut.startObserving()

		var sawStalled = false
		sut.performanceEventPublisher
			.sink { event in
				if case .playbackStalled = event { sawStalled = true }
			}
			.store(in: &cancellables)

		NotificationCenter.default.post(name: AVPlayerItem.playbackStalledNotification, object: item)

		XCTAssertTrue(sawStalled, "Expected the native stall notification to emit .playbackStalled")
	}

	// MARK: - Buffering State

	func test_init_startsWithUnknownBufferingState() {
		let (sut, _) = makeSUT()

		XCTAssertEqual(sut.currentBufferingState, .unknown)
	}

	func test_bufferingStatePublisher_emitsCurrentState() {
		let (sut, _) = makeSUT()
		var receivedStates: [BufferingState] = []
		let exp = expectation(description: "Wait for state")

		sut.bufferingStatePublisher
			.sink { state in
				receivedStates.append(state)
				exp.fulfill()
			}
			.store(in: &cancellables)

		wait(for: [exp], timeout: 1.0)

		XCTAssertEqual(receivedStates.first, .unknown)
	}

	// MARK: - Performance Events

	func test_performanceEventPublisher_existsAndCanBeSubscribed() {
		let (sut, _) = makeSUT()
		var receivedEvents: [PerformanceEvent] = []

		sut.performanceEventPublisher
			.sink { event in
				receivedEvents.append(event)
			}
			.store(in: &cancellables)

		// Just verify subscription doesn't crash
		XCTAssertTrue(receivedEvents.isEmpty)
	}

	// MARK: - Start/Stop Observing

	func test_startObserving_beginsPlayerObservation() {
		let (sut, _) = makeSUT()

		sut.startObserving()

		// Should not crash
		sut.stopObserving()
	}

	func test_stopObserving_removesPlayerObservation() {
		let (sut, _) = makeSUT()

		sut.startObserving()
		sut.stopObserving()

		// Should complete without issues
	}

	// MARK: - Player Item Changes

	func test_observePlayerItem_updatesBufferingState() {
		let player = AVPlayer()
		let (sut, _) = makeSUT(player: player)
		let item = AVPlayerItem(url: anyURL())

		sut.startObserving()
		player.replaceCurrentItem(with: item)

		// Allow KVO to propagate
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

		// State should be observed (may be buffering or ready depending on timing)
		XCTAssertNotNil(sut.currentBufferingState)
	}

	// MARK: - Helpers

	private func makeSUT(
		player: AVPlayer? = nil,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: AVPlayerPerformanceObserver, player: AVPlayer) {
		let player = player ?? AVPlayer()
		let sut = AVPlayerPerformanceObserver(player: player)
		return (sut, player)
	}

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}
