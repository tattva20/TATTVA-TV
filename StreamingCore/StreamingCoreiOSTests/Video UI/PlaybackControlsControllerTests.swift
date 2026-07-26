//
//  PlaybackControlsControllerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore
import StreamingCoreiOS

@MainActor
final class PlaybackControlsControllerTests: XCTestCase {

	private var sut: PlaybackControlsController?

	func test_init_doesNotIssuePlayerCommands() {
		let (_, player, _) = makeSUT()

		XCTAssertEqual(player.playCallCount, 0)
		XCTAssertEqual(player.pauseCallCount, 0)
	}

	func test_playTapped_whenPaused_playsAndReportsInteraction() {
		let (controlsView, player, delegate) = makeSUT()

		controlsView.onPlayTapped?()

		XCTAssertEqual(player.playCallCount, 1)
		XCTAssertEqual(player.pauseCallCount, 0)
		XCTAssertEqual(delegate.interactCallCount, 1)
		XCTAssertEqual(delegate.pauseCallCount, 0)
	}

	func test_playTapped_whenPlaying_pausesAndReportsPause() {
		let (controlsView, player, delegate) = makeSUT()
		player.isPlaying = true

		controlsView.onPlayTapped?()

		XCTAssertEqual(player.pauseCallCount, 1)
		XCTAssertEqual(player.playCallCount, 0)
		XCTAssertEqual(delegate.pauseCallCount, 1)
		XCTAssertEqual(delegate.interactCallCount, 0)
	}

	func test_seekForward_seeksAndReportsInteraction() {
		let (controlsView, player, delegate) = makeSUT()

		controlsView.onSeekForwardTapped?()

		XCTAssertEqual(player.seekForwardCallCount, 1)
		XCTAssertEqual(delegate.interactCallCount, 1)
	}

	func test_seekBackward_seeksAndReportsInteraction() {
		let (controlsView, player, delegate) = makeSUT()

		controlsView.onSeekBackwardTapped?()

		XCTAssertEqual(player.seekBackwardCallCount, 1)
		XCTAssertEqual(delegate.interactCallCount, 1)
	}

	func test_progressChanged_seeksToProportionalTimeAndReportsInteraction() {
		let (controlsView, player, delegate) = makeSUT()
		player.duration = 100

		controlsView.onProgressChanged?(0.5)

		XCTAssertEqual(player.seekToTimes, [50])
		XCTAssertEqual(delegate.interactCallCount, 1)
	}

	func test_muteTapped_togglesMute() {
		let (controlsView, player, _) = makeSUT()
		XCTAssertFalse(player.isMuted)

		controlsView.onMuteTapped?()
		XCTAssertTrue(player.isMuted)

		controlsView.onMuteTapped?()
		XCTAssertFalse(player.isMuted)
	}

	func test_volumeChanged_setsVolume() {
		let (controlsView, player, _) = makeSUT()

		controlsView.onVolumeChanged?(0.7)

		XCTAssertEqual(player.volume, 0.7, accuracy: 0.01)
	}

	func test_speedTapped_cyclesThroughSpeeds() {
		let (controlsView, player, _) = makeSUT()
		XCTAssertEqual(player.playbackSpeed, 1.0, accuracy: 0.01)

		let expected: [Float] = [1.25, 1.5, 2.0, 0.5, 1.0]
		for speed in expected {
			controlsView.onSpeedTapped?()
			XCTAssertEqual(player.playbackSpeed, speed, accuracy: 0.01)
		}
	}

	func test_fullscreenTapped_reportsFullscreenToggle() {
		let (controlsView, _, delegate) = makeSUT()

		controlsView.onFullscreenTapped?()

		XCTAssertEqual(delegate.fullscreenCallCount, 1)
	}

	func test_pipTapped_reportsPictureInPictureToggle() {
		let (controlsView, _, delegate) = makeSUT()

		controlsView.onPipTapped?()

		XCTAssertEqual(delegate.pipCallCount, 1)
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (controlsView: VideoPlayerControls, player: VideoPlayerSpy, delegate: DelegateSpy) {
		let player = VideoPlayerSpy()
		let controlsView = VideoPlayerControls()
		let delegate = DelegateSpy()
		let controller = PlaybackControlsController(player: player, controlsView: controlsView, delegate: delegate)
		sut = controller
		trackForMemoryLeaks(controller, file: file, line: line)
		trackForMemoryLeaks(player, file: file, line: line)
		trackForMemoryLeaks(delegate, file: file, line: line)
		addTeardownBlock { [weak self] in self?.sut = nil }
		return (controlsView, player, delegate)
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}

	private final class DelegateSpy: PlaybackControlsControllerDelegate {
		private(set) var interactCallCount = 0
		private(set) var pauseCallCount = 0
		private(set) var fullscreenCallCount = 0
		private(set) var pipCallCount = 0

		func playbackControlsDidInteract() { interactCallCount += 1 }
		func playbackControlsDidPause() { pauseCallCount += 1 }
		func playbackControlsDidToggleFullscreen() { fullscreenCallCount += 1 }
		func playbackControlsDidTogglePictureInPicture() { pipCallCount += 1 }
	}

	private final class VideoPlayerSpy: VideoPlayer {
		private(set) var playCallCount = 0
		private(set) var pauseCallCount = 0
		private(set) var loadedURLs = [URL]()
		private(set) var seekForwardCallCount = 0
		private(set) var seekBackwardCallCount = 0
		private(set) var seekToTimes = [TimeInterval]()

		var isPlaying: Bool = false
		var currentTime: TimeInterval = 0
		var duration: TimeInterval = 0
		var volume: Float = 1.0
		var isMuted: Bool = false
		var playbackSpeed: Float = 1.0

		func load(url: URL) { loadedURLs.append(url) }
		func play() { playCallCount += 1; isPlaying = true }
		func pause() { pauseCallCount += 1; isPlaying = false }
		func seekForward(by seconds: TimeInterval) { seekForwardCallCount += 1 }
		func seekBackward(by seconds: TimeInterval) { seekBackwardCallCount += 1 }
		func seek(to time: TimeInterval) { seekToTimes.append(time) }
		func setVolume(_ volume: Float) { self.volume = volume }
		func toggleMute() { isMuted.toggle() }
		func setPlaybackSpeed(_ speed: Float) { playbackSpeed = speed }
	}
}
