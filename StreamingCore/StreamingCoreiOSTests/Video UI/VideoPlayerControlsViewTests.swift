//
//  VideoPlayerControlsViewTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCoreiOS

@MainActor
final class VideoPlayerControlsViewTests: XCTestCase {

	// MARK: - UI Element Creation Tests

	func test_init_createsPlayButton() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.playButton)
		XCTAssertEqual(sut.playButton.tintColor, .white)
	}

	func test_init_createsSeekButtons() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.seekForwardButton)
		XCTAssertNotNil(sut.seekBackwardButton)
		XCTAssertEqual(sut.seekForwardButton.tintColor, .white)
		XCTAssertEqual(sut.seekBackwardButton.tintColor, .white)
	}

	func test_init_createsProgressSlider() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.progressSlider)
		XCTAssertEqual(sut.progressSlider.minimumValue, 0)
		XCTAssertEqual(sut.progressSlider.maximumValue, 1)
	}

	func test_init_createsTimeLabels() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.currentTimeLabel)
		XCTAssertNotNil(sut.durationLabel)
		XCTAssertEqual(sut.currentTimeLabel.text, "0:00")
		XCTAssertEqual(sut.durationLabel.text, "0:00")
	}

	func test_init_createsMuteButton() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.muteButton)
		XCTAssertEqual(sut.muteButton.tintColor, .white)
	}

	func test_init_createsVolumeSlider() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.volumeSlider)
		XCTAssertEqual(sut.volumeSlider.minimumValue, 0)
		XCTAssertEqual(sut.volumeSlider.maximumValue, 1)
		XCTAssertEqual(sut.volumeSlider.value, 1)
	}

	func test_init_createsPlaybackSpeedButton() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.playbackSpeedButton)
		XCTAssertEqual(sut.playbackSpeedButton.title(for: .normal), "1x")
	}

	func test_init_createsFullscreenButton() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.fullscreenButton)
		XCTAssertEqual(sut.fullscreenButton.tintColor, .white)
	}

	func test_init_createsPipButton() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.pipButton)
		XCTAssertEqual(sut.pipButton.tintColor, .white)
	}

	func test_init_createsLandscapeTitleLabel() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.landscapeTitleLabel)
		XCTAssertTrue(sut.landscapeTitleLabel.isHidden)
	}

	func test_init_createsBottomControlsContainer() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.bottomControlsContainer)
	}

	// MARK: - Callback Tests

	func test_playButtonTap_callsOnPlayTapped() {
		let sut = makeSUT()
		var callCount = 0
		sut.onPlayTapped = { callCount += 1 }

		sut.playButton.simulateTap()

		XCTAssertEqual(callCount, 1)
	}

	func test_seekForwardButtonTap_callsOnSeekForwardTapped() {
		let sut = makeSUT()
		var callCount = 0
		sut.onSeekForwardTapped = { callCount += 1 }

		sut.seekForwardButton.simulateTap()

		XCTAssertEqual(callCount, 1)
	}

	func test_seekBackwardButtonTap_callsOnSeekBackwardTapped() {
		let sut = makeSUT()
		var callCount = 0
		sut.onSeekBackwardTapped = { callCount += 1 }

		sut.seekBackwardButton.simulateTap()

		XCTAssertEqual(callCount, 1)
	}

	func test_progressSliderValueChanged_callsOnProgressChanged() {
		let sut = makeSUT()
		var receivedValue: Float?
		sut.onProgressChanged = { receivedValue = $0 }

		sut.progressSlider.value = 0.5
		sut.progressSlider.simulate(event: .valueChanged)

		XCTAssertEqual(receivedValue, 0.5)
	}

	func test_muteButtonTap_callsOnMuteTapped() {
		let sut = makeSUT()
		var callCount = 0
		sut.onMuteTapped = { callCount += 1 }

		sut.muteButton.simulateTap()

		XCTAssertEqual(callCount, 1)
	}

	func test_volumeSliderValueChanged_callsOnVolumeChanged() {
		let sut = makeSUT()
		var receivedValue: Float?
		sut.onVolumeChanged = { receivedValue = $0 }

		sut.volumeSlider.value = 0.7
		sut.volumeSlider.simulate(event: .valueChanged)

		XCTAssertEqual(receivedValue, 0.7)
	}

	func test_playbackSpeedButtonTap_callsOnSpeedTapped() {
		let sut = makeSUT()
		var callCount = 0
		sut.onSpeedTapped = { callCount += 1 }

		sut.playbackSpeedButton.simulateTap()

		XCTAssertEqual(callCount, 1)
	}

	func test_fullscreenButtonTap_callsOnFullscreenTapped() {
		let sut = makeSUT()
		var callCount = 0
		sut.onFullscreenTapped = { callCount += 1 }

		sut.fullscreenButton.simulateTap()

		XCTAssertEqual(callCount, 1)
	}

	func test_pipButtonTap_callsOnPipTapped() {
		let sut = makeSUT()
		var callCount = 0
		sut.onPipTapped = { callCount += 1 }

		sut.pipButton.simulateTap()

		XCTAssertEqual(callCount, 1)
	}

	// MARK: - State Update Tests

	func test_setPlayButtonPlaying_true_showsPauseIcon() {
		let sut = makeSUT()

		sut.setPlayButtonPlaying(true)

		XCTAssertEqual(sut.playButton.image(for: .normal), UIImage(systemName: "pause.fill"))
	}

	func test_setPlayButtonPlaying_false_showsPlayIcon() {
		let sut = makeSUT()

		sut.setPlayButtonPlaying(false)

		XCTAssertEqual(sut.playButton.image(for: .normal), UIImage(systemName: "play.fill"))
	}

	func test_setMuteButtonMuted_true_showsMutedIcon() {
		let sut = makeSUT()

		sut.setMuteButtonMuted(true)

		XCTAssertEqual(sut.muteButton.image(for: .normal), UIImage(systemName: "speaker.slash.fill"))
	}

	func test_setMuteButtonMuted_false_showsUnmutedIcon() {
		let sut = makeSUT()

		sut.setMuteButtonMuted(false)

		XCTAssertEqual(sut.muteButton.image(for: .normal), UIImage(systemName: "speaker.wave.2.fill"))
	}

	func test_setFullscreenButtonExpanded_true_showsCollapseIcon() {
		let sut = makeSUT()

		sut.setFullscreenButtonExpanded(true)

		XCTAssertEqual(sut.fullscreenButton.image(for: .normal), UIImage(systemName: "arrow.down.right.and.arrow.up.left"))
	}

	func test_setFullscreenButtonExpanded_false_showsExpandIcon() {
		let sut = makeSUT()

		sut.setFullscreenButtonExpanded(false)

		XCTAssertEqual(sut.fullscreenButton.image(for: .normal), UIImage(systemName: "arrow.up.left.and.arrow.down.right"))
	}

	func test_setSpeedButtonTitle_updatesTitle() {
		let sut = makeSUT()

		sut.setSpeedButtonTitle("2x")

		XCTAssertEqual(sut.playbackSpeedButton.title(for: .normal), "2x")
	}

	func test_updateTime_updatesLabelsAndSlider() {
		let sut = makeSUT()

		sut.updateTime(current: "1:30", duration: "5:00", progress: 0.3)

		XCTAssertEqual(sut.currentTimeLabel.text, "1:30")
		XCTAssertEqual(sut.durationLabel.text, "5:00")
		XCTAssertEqual(sut.progressSlider.value, 0.3)
	}

	func test_setTitle_updatesLandscapeTitleLabel() {
		let sut = makeSUT()

		sut.setTitle("Test Video")

		XCTAssertEqual(sut.landscapeTitleLabel.text, "Test Video")
	}

	// MARK: - Layout Tests

	func test_updateLayout_portrait_showsBottomControlsContainer() {
		let sut = makeSUT()

		sut.updateLayout(for: .portrait)

		XCTAssertFalse(sut.bottomControlsContainer.isHidden)
	}

	func test_updateLayout_landscape_hidesBottomControlsContainer() {
		let sut = makeSUT()

		sut.updateLayout(for: .landscape)

		XCTAssertTrue(sut.bottomControlsContainer.isHidden)
	}

	func test_updateLayout_portrait_hidesLandscapeTitleLabel() {
		let sut = makeSUT()

		sut.updateLayout(for: .portrait)

		XCTAssertTrue(sut.landscapeTitleLabel.isHidden)
	}

	func test_updateLayout_landscape_showsLandscapeTitleLabel() {
		let sut = makeSUT()

		sut.updateLayout(for: .landscape)

		XCTAssertFalse(sut.landscapeTitleLabel.isHidden)
	}

	// MARK: - Controls Alpha Tests

	func test_setControlsAlpha_portrait_setsOverlayControlsAlpha() {
		let sut = makeSUT()

		sut.setControlsAlpha(0.5, isLandscape: false)

		XCTAssertEqual(sut.playButton.alpha, 0.5)
		XCTAssertEqual(sut.seekForwardButton.alpha, 0.5)
		XCTAssertEqual(sut.seekBackwardButton.alpha, 0.5)
		XCTAssertEqual(sut.progressSlider.alpha, 0.5)
		XCTAssertEqual(sut.currentTimeLabel.alpha, 0.5)
		XCTAssertEqual(sut.durationLabel.alpha, 0.5)
	}

	func test_setControlsAlpha_portrait_doesNotHideBottomControls() {
		let sut = makeSUT()
		sut.updateLayout(for: .portrait)

		sut.setControlsAlpha(0.0, isLandscape: false)

		// Bottom controls should remain visible in portrait
		XCTAssertEqual(sut.playbackSpeedButton.alpha, 1.0)
		XCTAssertEqual(sut.pipButton.alpha, 1.0)
		XCTAssertEqual(sut.fullscreenButton.alpha, 1.0)
	}

	func test_setControlsAlpha_landscape_setsAllControlsAlpha() {
		let sut = makeSUT()
		sut.updateLayout(for: .landscape)

		sut.setControlsAlpha(0.0, isLandscape: true)

		XCTAssertEqual(sut.playButton.alpha, 0.0)
		XCTAssertEqual(sut.playbackSpeedButton.alpha, 0.0)
		XCTAssertEqual(sut.pipButton.alpha, 0.0)
		XCTAssertEqual(sut.fullscreenButton.alpha, 0.0)
		XCTAssertEqual(sut.landscapeTitleLabel.alpha, 0.0)
	}

	func test_setControlsAlpha_portrait_show_restoresBottomControls() {
		let sut = makeSUT()
		sut.updateLayout(for: .portrait)
		sut.playbackSpeedButton.alpha = 0.0
		sut.pipButton.alpha = 0.0
		sut.fullscreenButton.alpha = 0.0

		sut.setControlsAlpha(1.0, isLandscape: false)

		XCTAssertEqual(sut.playbackSpeedButton.alpha, 1.0)
		XCTAssertEqual(sut.pipButton.alpha, 1.0)
		XCTAssertEqual(sut.fullscreenButton.alpha, 1.0)
	}

	// MARK: - Interaction State Tests

	func test_setLandscapeControlsInteraction_enabled_enablesButtons() {
		let sut = makeSUT()

		sut.setLandscapeControlsInteraction(enabled: true)

		XCTAssertTrue(sut.playbackSpeedButton.isUserInteractionEnabled)
		XCTAssertTrue(sut.pipButton.isUserInteractionEnabled)
		XCTAssertTrue(sut.fullscreenButton.isUserInteractionEnabled)
	}

	func test_setLandscapeControlsInteraction_disabled_disablesButtons() {
		let sut = makeSUT()

		sut.setLandscapeControlsInteraction(enabled: false)

		XCTAssertFalse(sut.playbackSpeedButton.isUserInteractionEnabled)
		XCTAssertFalse(sut.pipButton.isUserInteractionEnabled)
		XCTAssertFalse(sut.fullscreenButton.isUserInteractionEnabled)
	}

	// MARK: - Controls Visibility Animation Tests

	func test_animateControlsHidden_landscape_hidesAllControlsAndDisablesInteraction() {
		let sut = makeSUT()
		sut.updateLayout(for: .landscape)

		sut.animateControlsHidden(isLandscape: true)

		XCTAssertEqual(sut.playButton.alpha, 0.0)
		XCTAssertEqual(sut.pipButton.alpha, 0.0)
		XCTAssertEqual(sut.fullscreenButton.alpha, 0.0)
		XCTAssertFalse(sut.pipButton.isUserInteractionEnabled)
		XCTAssertFalse(sut.fullscreenButton.isUserInteractionEnabled)
	}

	func test_animateControlsVisible_landscape_showsAllControlsAndEnablesInteraction() {
		let sut = makeSUT()
		sut.updateLayout(for: .landscape)
		sut.animateControlsHidden(isLandscape: true)

		sut.animateControlsVisible(isLandscape: true)

		XCTAssertEqual(sut.playButton.alpha, 1.0)
		XCTAssertEqual(sut.pipButton.alpha, 1.0)
		XCTAssertEqual(sut.fullscreenButton.alpha, 1.0)
		XCTAssertTrue(sut.pipButton.isUserInteractionEnabled)
		XCTAssertTrue(sut.fullscreenButton.isUserInteractionEnabled)
	}

	func test_animateControlsHidden_portrait_hidesOverlayButKeepsBottomControls() {
		let sut = makeSUT()
		sut.updateLayout(for: .portrait)

		sut.animateControlsHidden(isLandscape: false)

		XCTAssertEqual(sut.playButton.alpha, 0.0)
		XCTAssertEqual(sut.pipButton.alpha, 1.0)
		XCTAssertEqual(sut.fullscreenButton.alpha, 1.0)
	}

	// MARK: - Helpers

	func test_configureAccessibility_setsControlLabels() {
		let sut = makeSUT()

		XCTAssertEqual(sut.playButton.accessibilityLabel, "Play")
		XCTAssertEqual(sut.seekForwardButton.accessibilityLabel, "Skip forward 10 seconds")
		XCTAssertEqual(sut.seekBackwardButton.accessibilityLabel, "Skip back 10 seconds")
		XCTAssertEqual(sut.muteButton.accessibilityLabel, "Mute")
		XCTAssertEqual(sut.fullscreenButton.accessibilityLabel, "Enter full screen")
		XCTAssertEqual(sut.pipButton.accessibilityLabel, "Picture in Picture")
		XCTAssertEqual(sut.progressSlider.accessibilityLabel, "Playback position")
		XCTAssertEqual(sut.volumeSlider.accessibilityLabel, "Volume")
	}

	func test_setPlayButtonPlaying_updatesAccessibilityLabel() {
		let sut = makeSUT()

		sut.setPlayButtonPlaying(true)
		XCTAssertEqual(sut.playButton.accessibilityLabel, "Pause")

		sut.setPlayButtonPlaying(false)
		XCTAssertEqual(sut.playButton.accessibilityLabel, "Play")
	}

	func test_updateTime_setsProgressSliderAccessibilityValue() {
		let sut = makeSUT()

		sut.updateTime(current: "0:30", duration: "2:00", progress: 0.25)

		XCTAssertEqual(sut.progressSlider.accessibilityValue, "0:30 of 2:00")
	}

	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> VideoPlayerControlsView {
		let sut = VideoPlayerControlsView()
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}
}

// MARK: - UIControl Test Helper

private extension UIControl {
	func simulate(event: UIControl.Event) {
		allTargets.forEach { target in
			actions(forTarget: target, forControlEvent: event)?.forEach {
				(target as NSObject).perform(Selector($0))
			}
		}
	}
}

private extension UIButton {
	func simulateTap() {
		simulate(event: .touchUpInside)
	}
}
