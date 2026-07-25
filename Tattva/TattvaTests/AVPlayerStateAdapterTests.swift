//
//  AVPlayerStateAdapterTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import AVFoundation
import Combine
import StreamingCore
@testable import StreamingCorePlayback

@MainActor
final class AVPlayerStateAdapterTests: XCTestCase {

	private var cancellables = Set<AnyCancellable>()
	private var retainedPlayer: AVPlayer?

	override func tearDown() {
		cancellables.removeAll()
		retainedPlayer = nil
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	// MARK: - Initialization

	func test_init_doesNotStartObserving() {
		let (_, stateMachineSpy) = makeSUT()

		XCTAssertTrue(stateMachineSpy.receivedActions.isEmpty)
	}

	// MARK: - Start/Stop Observing

	func test_startObserving_setsUpPlayerObservation() {
		let (sut, _) = makeSUT()

		sut.startObserving()

		XCTAssertTrue(sut.isObserving)
	}

	func test_stopObserving_clearsObservation() {
		let (sut, _) = makeSUT()
		sut.startObserving()

		sut.stopObserving()

		XCTAssertFalse(sut.isObserving)
	}

	// MARK: - Player Item Ready

	func test_playerItemBecomesReady_sendsDidBecomeReadyAction() async {
		let player = AVPlayer()
		let (sut, stateMachineSpy) = makeSUT(player: player)
		sut.startObserving()

		// Simulate player item becoming ready by sending directly
		await sut.simulatePlayerItemReady()

		await poll(until: { !stateMachineSpy.receivedActions.isEmpty })

		XCTAssertTrue(stateMachineSpy.receivedActions.contains(.didBecomeReady))
	}

	// MARK: - Playback Started

	func test_playerStartsPlaying_sendsDidStartPlayingAction() async {
		let (sut, stateMachineSpy) = makeSUT()
		sut.startObserving()

		await sut.simulatePlaybackStarted()

		await poll(until: { !stateMachineSpy.receivedActions.isEmpty })

		XCTAssertTrue(stateMachineSpy.receivedActions.contains(.didStartPlaying))
	}

	// MARK: - Playback Paused

	func test_playerPauses_sendsDidPauseAction() async {
		let (sut, stateMachineSpy) = makeSUT()
		sut.startObserving()

		await sut.simulatePlaybackPaused()

		await poll(until: { !stateMachineSpy.receivedActions.isEmpty })

		XCTAssertTrue(stateMachineSpy.receivedActions.contains(.didPause))
	}

	// MARK: - Buffering

	func test_bufferingStarts_sendsDidStartBufferingAction() async {
		let (sut, stateMachineSpy) = makeSUT()
		sut.startObserving()

		await sut.simulateBufferingStarted()

		await poll(until: { !stateMachineSpy.receivedActions.isEmpty })

		XCTAssertTrue(stateMachineSpy.receivedActions.contains(.didStartBuffering))
	}

	func test_bufferingEnds_sendsDidFinishBufferingAction() async {
		let (sut, stateMachineSpy) = makeSUT()
		sut.startObserving()

		await sut.simulateBufferingEnded()

		await poll(until: { !stateMachineSpy.receivedActions.isEmpty })

		XCTAssertTrue(stateMachineSpy.receivedActions.contains(.didFinishBuffering))
	}

	// MARK: - Playback End

	func test_playbackReachesEnd_sendsDidReachEndAction() async {
		let (sut, stateMachineSpy) = makeSUT()
		sut.startObserving()

		await sut.simulatePlaybackEnded()

		await poll(until: { !stateMachineSpy.receivedActions.isEmpty })

		XCTAssertTrue(stateMachineSpy.receivedActions.contains(.didReachEnd))
	}

	// MARK: - Failure

	func test_playbackFails_sendsDidFailAction() async {
		let (sut, stateMachineSpy) = makeSUT()
		sut.startObserving()
		let error = NSError(domain: "test", code: -1)

		await sut.simulatePlaybackFailed(error: error)

		await poll(until: { !stateMachineSpy.receivedActions.isEmpty })

		let hasFailAction = stateMachineSpy.receivedActions.contains { action in
			if case .didFail = action { return true }
			return false
		}
		XCTAssertTrue(hasFailAction)
	}

	// MARK: - Helpers

	@discardableResult
	private func poll(
		until condition: @MainActor () -> Bool,
		timeout: TimeInterval = 1
	) async -> Bool {
		let deadline = Date() + timeout
		while Date() < deadline {
			if condition() { return true }
			await Task.yield()
		}
		return condition()
	}

	private func makeSUT(
		player: AVPlayer? = nil,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: AVPlayerStateAdapter, stateMachineSpy: StateMachineSpy) {
		let testPlayer = player ?? AVPlayer()
		retainedPlayer = testPlayer
		let stateMachineSpy = StateMachineSpy()
		let sut = AVPlayerStateAdapter(player: testPlayer, onAction: { [stateMachineSpy] action in
			stateMachineSpy.send(action)
		})
		return (sut, stateMachineSpy)
	}
}

// MARK: - Test Doubles

private final class StateMachineSpy: @unchecked Sendable {
	private var _receivedActions: [PlaybackAction] = []
	private let lock = NSLock()

	var receivedActions: [PlaybackAction] {
		lock.lock()
		defer { lock.unlock() }
		return _receivedActions
	}

	func send(_ action: PlaybackAction) {
		lock.lock()
		defer { lock.unlock() }
		_receivedActions.append(action)
	}
}
