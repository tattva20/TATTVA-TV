//
//  VideoPlayerViewControllerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore
import StreamingCoreiOS

@MainActor
class VideoPlayerViewControllerTests: XCTestCase {

	func test_viewDidLoad_setsTitle() {
		let (sut, _) = makeSUT(viewModel: makeViewModel(title: "a title"))

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.title, "a title")
	}

	func test_playButtonTap_startsPlayback() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulatePlayButtonTap()

		XCTAssertEqual(player.playCallCount, 1)
	}

	func test_playButtonTap_togglesPlayPause() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulatePlayButtonTap()
		XCTAssertEqual(player.playCallCount, 1)
		XCTAssertEqual(player.pauseCallCount, 0)

		sut.simulatePlayButtonTap()
		XCTAssertEqual(player.playCallCount, 1)
		XCTAssertEqual(player.pauseCallCount, 1)
	}

	func test_viewWillDisappear_pausesPlaybackWhenPictureInPictureIsInactive() {
		let (sut, player) = makeSUT()
		sut.loadViewIfNeeded()

		sut.viewWillDisappear(false)

		XCTAssertEqual(player.pauseCallCount, 1)
	}

	func test_viewWillDisappear_doesNotPausePlaybackWhilePictureInPictureIsActive() {
		let (sut, player) = makeSUT()
		sut.loadViewIfNeeded()
		sut.pipController = PictureInPictureControllingStub(isActive: true)

		sut.viewWillDisappear(false)

		XCTAssertEqual(player.pauseCallCount, 0)
	}

	func test_seekForwardButtonTap_seeksForward() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulateSeekForwardButtonTap()

		XCTAssertEqual(player.seekForwardCallCount, 1)
	}

	func test_seekBackwardButtonTap_seeksBackward() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulateSeekBackwardButtonTap()

		XCTAssertEqual(player.seekBackwardCallCount, 1)
	}

	func test_progressSliderValueChanged_seeksToPosition() {
		let (sut, player) = makeSUT()
		player.duration = 100

		sut.loadViewIfNeeded()
		sut.simulateProgressSliderValueChanged(to: 0.5)

		XCTAssertEqual(player.seekToTimes, [50])
	}

	func test_timeLabelsUpdate_displaysFormattedTime() {
		let (sut, player) = makeSUT()
		player.currentTime = 65
		player.duration = 3661

		sut.loadViewIfNeeded()
		sut.simulateTimeUpdate()

		XCTAssertEqual(sut.controlsView.currentTimeLabel.text, "1:05")
		XCTAssertEqual(sut.controlsView.durationLabel.text, "1:01:01")
	}

	func test_progressSlider_updatesWithCurrentTime() {
		let (sut, player) = makeSUT()
		player.currentTime = 30
		player.duration = 60

		sut.loadViewIfNeeded()
		sut.simulateTimeUpdate()

		XCTAssertEqual(sut.controlsView.progressSlider.value, 0.5, accuracy: 0.01)
	}

	func test_muteButtonTap_togglesMute() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		XCTAssertFalse(player.isMuted)

		sut.simulateMuteButtonTap()
		XCTAssertTrue(player.isMuted)

		sut.simulateMuteButtonTap()
		XCTAssertFalse(player.isMuted)
	}

	func test_volumeSliderValueChanged_setsVolume() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulateVolumeSliderValueChanged(to: 0.7)

		XCTAssertEqual(player.volume, 0.7, accuracy: 0.01)
	}

	func test_playbackSpeedButtonTap_cyclesThroughSpeeds() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		XCTAssertEqual(player.playbackSpeed, 1.0, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 1.25, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 1.5, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 2.0, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 0.5, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 1.0, accuracy: 0.01)
	}

	func test_fullscreenButtonTap_callsToggleCallback() {
		let (sut, _) = makeSUT()
		var toggleCallCount = 0
		sut.onFullscreenToggle = { toggleCallCount += 1 }

		sut.loadViewIfNeeded()
		XCTAssertEqual(toggleCallCount, 0)

		sut.simulateFullscreenButtonTap()
		XCTAssertEqual(toggleCallCount, 1)

		sut.simulateFullscreenButtonTap()
		XCTAssertEqual(toggleCallCount, 2)
	}

	func test_tapOnPlayerView_togglesControlsVisibility() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()
		XCTAssertTrue(sut.areControlsVisible)

		sut.simulateTapOnPlayerView()
		XCTAssertFalse(sut.areControlsVisible)

		sut.simulateTapOnPlayerView()
		XCTAssertTrue(sut.areControlsVisible)
	}

	func test_viewDidLoad_loadsVideoURL() {
		let url = URL(string: "https://a-video-url.com")!
		let (sut, player) = makeSUT(viewModel: makeViewModel(videoURL: url))

		sut.loadViewIfNeeded()

		XCTAssertEqual(player.loadedURLs, [url])
	}

	func test_playbackControls_haveFullAlphaInitially() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.controlsView.playButton.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.seekForwardButton.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.seekBackwardButton.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.progressSlider.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.currentTimeLabel.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.durationLabel.alpha, 1.0)
	}

	func test_viewDidLoad_displaysPipButton() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertNotNil(sut.controlsView.pipButton)
		XCTAssertNotNil(sut.controlsView.pipButton.superview)
	}

	func test_pipButton_hasCorrectIcon() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		let expectedImage = UIImage(systemName: "pip.enter")
		XCTAssertEqual(sut.controlsView.pipButton.image(for: .normal), expectedImage)
	}

	func test_pipButton_hasWhiteTintColor() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.controlsView.pipButton.tintColor, .white)
	}

	func test_pipButton_hasFullAlphaInitially() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.controlsView.pipButton.alpha, 1.0)
	}

	func test_hideControls_inPortrait_keepsPipButtonVisible() {
		let (sut, player) = makeSUT()
		player.isPlaying = true

		sut.loadViewIfNeeded()
		sut.simulateTapOnPlayerView()

		// In portrait mode, bottom controls (pip, speed, fullscreen) remain visible
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 1.0)
	}

	func test_hideControls_inLandscape_setsPipButtonAlphaToZero() {
		let (sut, player) = makeSUT()
		player.isPlaying = true

		sut.loadViewIfNeeded()
		sut.simulateLandscapeOrientation()
		sut.simulateTapOnPlayerView()

		// In landscape mode, ALL controls hide together including pip button
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 0.0)
	}

	func test_showControls_restoresPipButtonAlpha() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulateTapOnPlayerView()
		sut.simulateTapOnPlayerView()

		XCTAssertEqual(sut.controlsView.pipButton.alpha, 1.0)
	}

	func test_pipButtonTap_callsToggleCallback() {
		let (sut, _) = makeSUT()
		var toggleCallCount = 0
		sut.onPipToggle = { toggleCallCount += 1 }

		sut.loadViewIfNeeded()
		XCTAssertEqual(toggleCallCount, 0)

		sut.simulatePipButtonTap()
		XCTAssertEqual(toggleCallCount, 1)

		sut.simulatePipButtonTap()
		XCTAssertEqual(toggleCallCount, 2)
	}

	func test_hideControls_setsPlaybackControlsAlphaToZero() {
		let (sut, player) = makeSUT()
		player.isPlaying = true

		sut.loadViewIfNeeded()
		sut.simulateTapOnPlayerView()

		XCTAssertEqual(sut.controlsView.playButton.alpha, 0.0)
		XCTAssertEqual(sut.controlsView.seekForwardButton.alpha, 0.0)
		XCTAssertEqual(sut.controlsView.seekBackwardButton.alpha, 0.0)
		XCTAssertEqual(sut.controlsView.progressSlider.alpha, 0.0)
		XCTAssertEqual(sut.controlsView.currentTimeLabel.alpha, 0.0)
		XCTAssertEqual(sut.controlsView.durationLabel.alpha, 0.0)
	}

	func test_showControls_restoresPlaybackControlsAlpha() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulateTapOnPlayerView()
		sut.simulateTapOnPlayerView()

		XCTAssertEqual(sut.controlsView.playButton.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.seekForwardButton.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.seekBackwardButton.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.progressSlider.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.currentTimeLabel.alpha, 1.0)
		XCTAssertEqual(sut.controlsView.durationLabel.alpha, 1.0)
	}

	// MARK: - Helpers

	private func makeSUT(
		viewModel: VideoPlayerViewModel? = nil,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: VideoPlayerViewController, player: VideoPlayerSpy) {
		let player = VideoPlayerSpy()
		let vm = viewModel ?? makeViewModel()
		let sut = VideoPlayerViewController(viewModel: vm, player: player)
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(player, file: file, line: line)
		return (sut, player)
	}

	private func makeViewModel(
		title: String = "any title",
		videoURL: URL = URL(string: "https://any-url.com")!
	) -> VideoPlayerViewModel {
		VideoPlayerViewModel(title: title, videoURL: videoURL)
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}

	private class VideoPlayerSpy: VideoPlayer {
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

		func load(url: URL) {
			loadedURLs.append(url)
		}

		func play() {
			playCallCount += 1
			isPlaying = true
		}

		func pause() {
			pauseCallCount += 1
			isPlaying = false
		}

		func seekForward(by seconds: TimeInterval) {
			seekForwardCallCount += 1
		}

		func seekBackward(by seconds: TimeInterval) {
			seekBackwardCallCount += 1
		}

		func seek(to time: TimeInterval) {
			seekToTimes.append(time)
		}

		func setVolume(_ volume: Float) {
			self.volume = volume
		}

		func toggleMute() {
			isMuted.toggle()
		}

		func setPlaybackSpeed(_ speed: Float) {
			playbackSpeed = speed
		}
	}

	private final class PictureInPictureControllingStub: PictureInPictureControlling {
		var isPictureInPictureActive: Bool
		var isPictureInPicturePossible: Bool = true

		init(isActive: Bool) {
			self.isPictureInPictureActive = isActive
		}

		func togglePictureInPicture() {}
		func startPictureInPicture() {}
		func stopPictureInPicture() {}
	}
}

private extension VideoPlayerViewController {
	func simulatePlayButtonTap() {
		controlsView.playButton.simulate(event: .touchUpInside)
	}

	func simulateSeekForwardButtonTap() {
		controlsView.seekForwardButton.simulate(event: .touchUpInside)
	}

	func simulateSeekBackwardButtonTap() {
		controlsView.seekBackwardButton.simulate(event: .touchUpInside)
	}

	func simulateProgressSliderValueChanged(to value: Float) {
		controlsView.progressSlider.value = value
		controlsView.progressSlider.simulate(event: .valueChanged)
	}

	func simulateTimeUpdate() {
		updateTimeDisplay()
	}

	func simulateMuteButtonTap() {
		controlsView.muteButton.simulate(event: .touchUpInside)
	}

	func simulateVolumeSliderValueChanged(to value: Float) {
		controlsView.volumeSlider.value = value
		controlsView.volumeSlider.simulate(event: .valueChanged)
	}

	func simulatePlaybackSpeedButtonTap() {
		controlsView.playbackSpeedButton.simulate(event: .touchUpInside)
	}

	func simulateFullscreenButtonTap() {
		controlsView.fullscreenButton.simulate(event: .touchUpInside)
	}

	func simulatePipButtonTap() {
		controlsView.pipButton.simulate(event: .touchUpInside)
	}

	func simulateTapOnPlayerView() {
		toggleControlsVisibility()
	}

	func simulateLandscapeOrientation() {
		updateLayoutForOrientation(isLandscape: true)
	}
}

private extension UIControl {
	func simulate(event: UIControl.Event) {
		allTargets.forEach { target in
			actions(forTarget: target, forControlEvent: event)?.forEach {
				(target as NSObject).perform(Selector($0))
			}
		}
	}
}
