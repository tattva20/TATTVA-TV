//
//  VideoPlayerUIIntegrationTests.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore
import StreamingCoreiOS
@testable import Tattva

@MainActor
class VideoPlayerUIIntegrationTests: XCTestCase {

	override func tearDown() {
		super.tearDown()
		// Reset orientation lock to default after each test to prevent test pollution
		AppDelegate.orientationLock = .allButUpsideDown
		// Process any pending async work to avoid Swift runtime crash during deallocation
		for _ in 0..<3 {
			RunLoop.current.run(until: Date())
		}
	}

	func test_videoPlayerView_hasTitle() {
		let video = makeVideo(title: "a title")

		let sut = makeSUT(video: video)

		XCTAssertEqual(sut.title, "a title")
	}

	func test_videoPlayerView_hasPlayerView() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.playerView)
	}

	func test_videoPlayerView_displaysPlaybackControls() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.controlsView.playButton)
		XCTAssertNotNil(sut.controlsView.seekForwardButton)
		XCTAssertNotNil(sut.controlsView.seekBackwardButton)
		XCTAssertNotNil(sut.controlsView.progressSlider)
		XCTAssertNotNil(sut.controlsView.currentTimeLabel)
		XCTAssertNotNil(sut.controlsView.durationLabel)
		XCTAssertNotNil(sut.controlsView.muteButton)
		XCTAssertNotNil(sut.controlsView.volumeSlider)
		XCTAssertNotNil(sut.controlsView.playbackSpeedButton)
		XCTAssertNotNil(sut.controlsView.fullscreenButton)
	}

	func test_videoPlayerView_controlsAreVisibleInitially() {
		let sut = makeSUT()

		XCTAssertTrue(sut.areControlsVisible)
		XCTAssertEqual(sut.controlsView.playButton.alpha, 1.0)
	}

	func test_videoPlayerView_autoPlaysOnAppear() {
		let player = VideoPlayerSpy()
		let sut = makeSUT(player: player)

		sut.simulateViewDidAppear()

		XCTAssertTrue(player.isPlaying, "Expected video to auto-play when view appears")
	}

	func test_videoPlayerView_overlayControlsHideWhenAutoHideTriggersWhilePlayingInPortrait() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateControlsAutoHide()

		// Overlay controls should hide in portrait
		XCTAssertEqual(sut.controlsView.playButton.alpha, 0.0, "Expected play button to hide")
		XCTAssertEqual(sut.controlsView.seekForwardButton.alpha, 0.0, "Expected seek forward button to hide")
		XCTAssertEqual(sut.controlsView.seekBackwardButton.alpha, 0.0, "Expected seek backward button to hide")
		XCTAssertEqual(sut.controlsView.progressSlider.alpha, 0.0, "Expected progress slider to hide")
		XCTAssertEqual(sut.controlsView.currentTimeLabel.alpha, 0.0, "Expected current time label to hide")
		XCTAssertEqual(sut.controlsView.durationLabel.alpha, 0.0, "Expected duration label to hide")

		// Bottom controls should NOT hide in portrait
		XCTAssertEqual(sut.controlsView.muteButton.alpha, 1.0, "Expected mute button to remain visible in portrait")
		XCTAssertEqual(sut.controlsView.volumeSlider.alpha, 1.0, "Expected volume slider to remain visible in portrait")
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 1.0, "Expected playback speed button to remain visible in portrait")
		XCTAssertEqual(sut.controlsView.fullscreenButton.alpha, 1.0, "Expected fullscreen button to remain visible in portrait")
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 1.0, "Expected pip button to remain visible in portrait")
	}

	func test_videoPlayerView_allControlsHideWhenAutoHideTriggersWhilePlayingInLandscape() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateLandscapeOrientation()
		sut.simulateControlsAutoHide()

		// All controls should hide in landscape
		XCTAssertEqual(sut.controlsView.playButton.alpha, 0.0, "Expected play button to hide")
		XCTAssertEqual(sut.controlsView.muteButton.alpha, 0.0, "Expected mute button to hide in landscape")
		XCTAssertEqual(sut.controlsView.volumeSlider.alpha, 0.0, "Expected volume slider to hide in landscape")
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 0.0, "Expected playback speed button to hide in landscape")
		XCTAssertEqual(sut.controlsView.fullscreenButton.alpha, 0.0, "Expected fullscreen button to hide in landscape")
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 0.0, "Expected pip button to hide in landscape")
	}

	func test_videoPlayerView_controlsRemainVisibleWhenPaused() {
		let player = VideoPlayerSpy()
		player.isPlaying = false
		let sut = makeSUT(player: player)

		sut.simulateControlsAutoHide()

		XCTAssertEqual(sut.controlsView.playButton.alpha, 1.0, "Expected play button to remain visible when paused")
		XCTAssertEqual(sut.controlsView.muteButton.alpha, 1.0, "Expected mute button to remain visible when paused")
	}

	func test_videoPlayerView_showsControlsWhenVideoIsPaused() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateControlsAutoHide()
		XCTAssertEqual(sut.controlsView.playButton.alpha, 0.0, "Precondition: controls should be hidden")

		player.isPlaying = false
		sut.simulatePauseTriggered()

		XCTAssertEqual(sut.controlsView.playButton.alpha, 1.0, "Expected controls to show when video is paused")
	}

	func test_videoPlayerView_landscapeLayoutExpandsPlayerView() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertTrue(sut.isPlayerViewFullscreen, "Expected playerView to be fullscreen in landscape")
	}

	func test_videoPlayerView_hidesCommentsInLandscape() {
		let commentsController = UIViewController()
		let sut = makeSUT(commentsController: commentsController)

		sut.simulateLandscapeOrientation()

		XCTAssertTrue(sut.commentsContainerView?.isHidden ?? true, "Expected comments to be hidden in landscape")
	}

	func test_videoPlayerView_hidesBottomControlsInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertNotNil(sut.bottomControlsContainerView, "Expected to locate the bottom controls container")
		XCTAssertTrue(sut.bottomControlsContainerView?.isHidden ?? false, "Expected bottom controls container to be hidden in landscape")
	}

	func test_videoPlayerView_showsTitleLabelInLandscape() {
		let video = makeVideo(title: "Test Title")
		let sut = makeSUT(video: video)

		sut.simulateLandscapeOrientation()

		XCTAssertEqual(sut.controlsView.landscapeTitleLabel.text, "Test Title", "Expected title label to show video title")
		XCTAssertFalse(sut.controlsView.landscapeTitleLabel.isHidden, "Expected title label to be visible in landscape")
	}

	func test_videoPlayerView_titleLabelHasLowAlphaWhiteInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertEqual(sut.controlsView.landscapeTitleLabel.textColor, UIColor.white.withAlphaComponent(0.7), "Expected title label to have low alpha white color")
	}

	func test_videoPlayerView_titleLabelAutoHidesWithControlsInLandscape() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateLandscapeOrientation()
		XCTAssertEqual(sut.controlsView.landscapeTitleLabel.alpha, 1.0, "Precondition: title should be visible initially")

		sut.simulateControlsAutoHide()

		XCTAssertEqual(sut.controlsView.landscapeTitleLabel.alpha, 0.0, "Expected title label to auto-hide with controls")
	}

	func test_videoPlayerView_titleLabelShowsWithControlsWhenPaused() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateLandscapeOrientation()
		sut.simulateControlsAutoHide()
		XCTAssertEqual(sut.controlsView.landscapeTitleLabel.alpha, 0.0, "Precondition: title should be hidden")

		player.isPlaying = false
		sut.simulatePauseTriggered()

		XCTAssertEqual(sut.controlsView.landscapeTitleLabel.alpha, 1.0, "Expected title label to show with controls when paused")
	}

	func test_videoPlayerView_hidesTitleLabelInPortrait() {
		let sut = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertTrue(sut.controlsView.landscapeTitleLabel.isHidden, "Expected landscape title label to be hidden in portrait")
	}

	func test_videoPlayerView_hidesNavigationBarInLandscape() {
		let sut = makeUnTrackedSUT()
		let nav = UINavigationController(rootViewController: sut)
		nav.loadViewIfNeeded()
		sut.loadViewIfNeeded()

		sut.simulateLandscapeOrientation()

		XCTAssertTrue(nav.isNavigationBarHidden, "Expected navigation bar to be hidden in landscape")
	}

	func test_videoPlayerView_showsNavigationBarInPortrait() {
		let sut = makeUnTrackedSUT()
		let nav = UINavigationController(rootViewController: sut)
		nav.loadViewIfNeeded()
		sut.loadViewIfNeeded()
		sut.simulateLandscapeOrientation()

		sut.simulatePortraitOrientation()

		XCTAssertFalse(nav.isNavigationBarHidden, "Expected navigation bar to be visible in portrait")
	}

	func test_videoPlayerView_landscapeTitleLabelIsCentered() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

		sut.simulateLandscapeOrientation()
		sut.view.layoutIfNeeded()

		let titleCenterX = sut.controlsView.landscapeTitleLabel.center.x
		let viewCenterX = sut.view.bounds.width / 2
		XCTAssertEqual(titleCenterX, viewCenterX, accuracy: 1.0, "Expected title label to be centered horizontally")
	}

	func test_videoPlayerView_fullscreenButtonVisibleInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertEqual(sut.controlsView.fullscreenButton.alpha, 1.0, "Expected fullscreen button to be visible in landscape")
		XCTAssertFalse(sut.controlsView.fullscreenButton.isHidden, "Expected fullscreen button to not be hidden in landscape")
	}

	func test_videoPlayerView_fullscreenButtonCallsToggleHandler() {
		let sut = makeSUT()
		var toggleCallCount = 0
		sut.onFullscreenToggle = { toggleCallCount += 1 }

		sut.loadViewIfNeeded()
		sut.controlsView.fullscreenButton.simulateTap()

		XCTAssertEqual(toggleCallCount, 1, "Expected fullscreen toggle handler to be called once")
	}

	func test_videoPlayerView_fullscreenButtonIsPositionedNextToDurationLabelInLandscape() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

		sut.simulateLandscapeOrientation()
		sut.view.layoutIfNeeded()

		let fullscreenX = sut.controlsView.fullscreenButton.frame.minX
		let durationMaxX = sut.controlsView.durationLabel.frame.maxX
		XCTAssertGreaterThan(fullscreenX, durationMaxX, "Expected fullscreen button to be positioned after duration label")
	}

	func test_videoPlayerView_isFullscreenIsFalseInPortrait() {
		let sut = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertFalse(sut.isFullscreen, "Expected isFullscreen to be false in portrait")
	}

	func test_videoPlayerView_isFullscreenIsTrueInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertTrue(sut.isFullscreen, "Expected isFullscreen to be true in landscape")
	}

	func test_videoPlayerView_fullscreenButtonShowsExpandIconInPortrait() {
		let sut = makeSUT()

		sut.loadViewIfNeeded()

		let expectedImage = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
		XCTAssertEqual(sut.controlsView.fullscreenButton.image(for: .normal), expectedImage, "Expected expand icon in portrait")
	}

	func test_videoPlayerView_fullscreenButtonShowsCollapseIconInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		let expectedImage = UIImage(systemName: "arrow.down.right.and.arrow.up.left")
		XCTAssertEqual(sut.controlsView.fullscreenButton.image(for: .normal), expectedImage, "Expected collapse icon in landscape")
	}

	func test_videoPlayerView_fullscreenButtonIconUpdatesOnOrientationChange() {
		let sut = makeSUT()
		sut.loadViewIfNeeded()

		let expandIcon = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
		let collapseIcon = UIImage(systemName: "arrow.down.right.and.arrow.up.left")

		XCTAssertEqual(sut.controlsView.fullscreenButton.image(for: .normal), expandIcon, "Precondition: should show expand icon")

		sut.simulateLandscapeOrientation()
		XCTAssertEqual(sut.controlsView.fullscreenButton.image(for: .normal), collapseIcon, "Expected collapse icon after landscape")

		sut.simulatePortraitOrientation()
		XCTAssertEqual(sut.controlsView.fullscreenButton.image(for: .normal), expandIcon, "Expected expand icon after portrait")
	}

	func test_videoPlayerView_supportsAllOrientationsExceptUpsideDown() {
		let sut = makeSUT()

		XCTAssertEqual(sut.supportedInterfaceOrientations, .allButUpsideDown, "Expected explicit support for all orientations except upside down")
	}

	func test_videoPlayerView_pipButtonVisibleInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertEqual(sut.controlsView.pipButton.alpha, 1.0, "Expected pip button to be visible in landscape")
		XCTAssertFalse(sut.controlsView.pipButton.isHidden, "Expected pip button to not be hidden in landscape")
	}

	func test_videoPlayerView_pipButtonIsPositionedBetweenDurationAndFullscreenInLandscape() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

		sut.simulateLandscapeOrientation()
		sut.view.layoutIfNeeded()

		let pipButtonX = sut.controlsView.pipButton.frame.minX
		let durationMaxX = sut.controlsView.durationLabel.frame.maxX
		let fullscreenMinX = sut.controlsView.fullscreenButton.frame.minX
		XCTAssertGreaterThan(pipButtonX, durationMaxX, "Expected pip button to be positioned after duration label")
		XCTAssertLessThan(sut.controlsView.pipButton.frame.maxX, fullscreenMinX, "Expected pip button to be positioned before fullscreen button")
	}

	func test_videoPlayerView_pipButtonAutoHidesWithControlsInLandscape() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateLandscapeOrientation()
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 1.0, "Precondition: pip button should be visible initially")

		sut.simulateControlsAutoHide()

		XCTAssertEqual(sut.controlsView.pipButton.alpha, 0.0, "Expected pip button to auto-hide with controls in landscape")
	}

	func test_videoPlayerView_pipButtonShowsWithControlsWhenPausedInLandscape() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateLandscapeOrientation()
		sut.simulateControlsAutoHide()
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 0.0, "Precondition: pip button should be hidden")

		player.isPlaying = false
		sut.simulatePauseTriggered()

		XCTAssertEqual(sut.controlsView.pipButton.alpha, 1.0, "Expected pip button to show with controls when paused")
	}

	func test_videoPlayerView_landscapeControlsArePositioned64PointsFromBottom() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

		sut.simulateLandscapeOrientation()
		sut.view.layoutIfNeeded()

		let expectedBottomOffset: CGFloat = 64
		let playerViewBottom = sut.playerView.frame.maxY
		let controlsBottomY = sut.controlsView.currentTimeLabel.frame.maxY

		XCTAssertEqual(playerViewBottom - controlsBottomY, expectedBottomOffset, accuracy: 1.0, "Expected controls to be 64 points from the bottom of the player view in landscape")
	}

	func test_videoPlayerView_landscapeSliderIsPositioned64PointsFromBottom() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

		sut.simulateLandscapeOrientation()
		sut.view.layoutIfNeeded()

		let playerViewBottom = sut.playerView.frame.maxY
		let sliderCenterY = sut.controlsView.progressSlider.center.y
		let currentTimeCenterY = sut.controlsView.currentTimeLabel.center.y

		XCTAssertEqual(sliderCenterY, currentTimeCenterY, accuracy: 1.0, "Expected slider to be vertically aligned with time labels")
		XCTAssertLessThan(sut.controlsView.progressSlider.frame.maxY, playerViewBottom - 48, "Expected slider to be at least 48 points from the bottom")
	}

	func test_videoPlayerView_portraitControlsRemainAt16PointsFromBottom() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 400, height: 800)

		sut.loadViewIfNeeded()
		sut.view.layoutIfNeeded()

		let expectedBottomOffset: CGFloat = 16
		let playerViewBottom = sut.playerView.frame.maxY
		let controlsBottomY = sut.controlsView.currentTimeLabel.frame.maxY

		XCTAssertEqual(playerViewBottom - controlsBottomY, expectedBottomOffset, accuracy: 1.0, "Expected controls to remain 16 points from the bottom of the player view in portrait")
	}

	func test_videoPlayerView_speedButtonIsVisibleInPortrait() {
		let sut = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 1.0, "Expected speed button to be visible in portrait")
		XCTAssertFalse(sut.controlsView.playbackSpeedButton.isHidden, "Expected speed button to not be hidden in portrait")
	}

	func test_videoPlayerView_speedButtonIsVisibleInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 1.0, "Expected speed button to be visible in landscape")
		XCTAssertFalse(sut.controlsView.playbackSpeedButton.isHidden, "Expected speed button to not be hidden in landscape")
	}

	func test_videoPlayerView_speedButtonIsPositionedBetweenSliderAndPipInLandscape() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

		sut.simulateLandscapeOrientation()
		sut.view.layoutIfNeeded()

		let speedButtonMinX = sut.controlsView.playbackSpeedButton.frame.minX
		let speedButtonMaxX = sut.controlsView.playbackSpeedButton.frame.maxX
		let durationMaxX = sut.controlsView.durationLabel.frame.maxX
		let pipMinX = sut.controlsView.pipButton.frame.minX
		XCTAssertGreaterThan(speedButtonMinX, durationMaxX, "Expected speed button to be positioned after duration label in landscape")
		XCTAssertLessThan(speedButtonMaxX, pipMinX, "Expected speed button to be positioned before pip button in landscape")
	}

	func test_videoPlayerView_sliderHasReasonableWidthInPortrait() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 400, height: 800)

		sut.loadViewIfNeeded()
		sut.view.layoutIfNeeded()

		let sliderWidth = sut.controlsView.progressSlider.frame.width
		let viewWidth = sut.view.frame.width
		let minExpectedWidth = viewWidth * 0.5 // Slider should be at least 50% of view width in portrait
		XCTAssertGreaterThan(sliderWidth, minExpectedWidth, "Expected slider to have reasonable width in portrait (got \(sliderWidth), expected at least \(minExpectedWidth))")
	}

	func test_videoPlayerView_sliderHasReasonableWidthInLandscape() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

		sut.simulateLandscapeOrientation()
		sut.view.layoutIfNeeded()

		let sliderWidth = sut.controlsView.progressSlider.frame.width
		let viewWidth = sut.view.frame.width
		let minExpectedWidth = viewWidth * 0.4 // Slider should be at least 40% of view width in landscape (accounting for more controls)
		XCTAssertGreaterThan(sliderWidth, minExpectedWidth, "Expected slider to have reasonable width in landscape (got \(sliderWidth), expected at least \(minExpectedWidth))")
	}

	func test_videoPlayerView_speedButtonRemainsVisibleAfterLandscapeToPortraitTransition() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		// Go to landscape and trigger auto-hide (which hides speed button)
		sut.simulateLandscapeOrientation()
		sut.simulateControlsAutoHide()
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 0.0, "Precondition: speed button should be hidden in landscape after auto-hide")

		// Return to portrait - speed button should be restored
		sut.simulatePortraitOrientation()
		sut.simulatePauseTriggered()

		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 1.0, "Expected speed button to be restored after returning to portrait")
	}

	// MARK: - Orientation Tests

	// IMPORTANT: The fullscreen toggle should NEVER modify AppDelegate.orientationLock.
	// Using orientation locks causes iOS to cache the restricted orientation mask,
	// which blocks physical rotation even after the lock is reset.
	// The correct approach is to use requestGeometryUpdate WITHOUT any orientation locking.
	// Reference: commits 5473c40 and 4705375 show the original working implementation.

	func test_fullscreenToggle_neverModifiesOrientationLock() {
		let sut = makeSUT()
		sut.loadViewIfNeeded()

		// Verify orientation lock starts at default
		XCTAssertEqual(AppDelegate.orientationLock, .allButUpsideDown, "Precondition: orientation lock should be at default")

		// Trigger fullscreen toggle
		sut.onFullscreenToggle?()

		// Orientation lock should NEVER be modified - not even temporarily
		// This is critical: using orientation locks causes iOS to cache restrictions
		XCTAssertEqual(AppDelegate.orientationLock, .allButUpsideDown, "Expected orientation lock to NEVER be modified during fullscreen toggle")
	}

	func test_fullscreenToggle_fromPortraitToLandscape_doesNotLockOrientation() {
		let sut = makeSUT()
		sut.loadViewIfNeeded()

		// Start in portrait (isFullscreen = false)
		XCTAssertFalse(sut.isFullscreen, "Precondition: should start in portrait")

		// Toggle to landscape
		sut.onFullscreenToggle?()

		// Orientation lock should remain at default - physical rotation should still work
		XCTAssertEqual(AppDelegate.orientationLock, .allButUpsideDown, "Expected orientation lock to remain at default after toggling to landscape")
	}

	func test_fullscreenToggle_fromLandscapeToPortrait_doesNotLockOrientation() {
		let sut = makeSUT()
		sut.loadViewIfNeeded()
		sut.simulateLandscapeOrientation()

		// Start in landscape (isFullscreen = true)
		XCTAssertTrue(sut.isFullscreen, "Precondition: should be in landscape/fullscreen")

		// Toggle back to portrait
		sut.onFullscreenToggle?()

		// Orientation lock should remain at default - physical rotation should still work
		XCTAssertEqual(AppDelegate.orientationLock, .allButUpsideDown, "Expected orientation lock to remain at default after toggling to portrait")
	}

	// MARK: - Fullscreen Button Controls Visibility Tests

	func test_fullscreenButtonTap_inLandscapeWithHiddenControls_keepsControlsHiddenUntilOrientationChanges() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		// Go to landscape and trigger auto-hide
		sut.simulateLandscapeOrientation()
		sut.simulateControlsAutoHide()

		// Verify controls are hidden
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 0.0, "Precondition: speed button should be hidden")
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 0.0, "Precondition: pip button should be hidden")
		XCTAssertEqual(sut.controlsView.fullscreenButton.alpha, 0.0, "Precondition: fullscreen button should be hidden")

		// Tap fullscreen button (while hidden) - should NOT make controls visible in landscape
		sut.controlsView.fullscreenButton.simulateTap()

		// Controls should remain hidden in landscape (until orientation actually changes)
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 0.0, "Expected speed button to remain hidden after fullscreen tap in landscape")
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 0.0, "Expected pip button to remain hidden after fullscreen tap in landscape")
		XCTAssertEqual(sut.controlsView.fullscreenButton.alpha, 0.0, "Expected fullscreen button to remain hidden after fullscreen tap in landscape")
	}

	func test_fullscreenButtonTap_inLandscapeWithHiddenControls_controlsBecomeVisibleAfterPortraitTransition() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		// Go to landscape and trigger auto-hide
		sut.simulateLandscapeOrientation()
		sut.simulateControlsAutoHide()

		// Tap fullscreen button and then simulate the resulting portrait orientation
		sut.controlsView.fullscreenButton.simulateTap()
		sut.simulatePortraitOrientation()

		// After transition to portrait, controls should be visible (portrait always shows bottom controls)
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 1.0, "Expected speed button to be visible in portrait")
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 1.0, "Expected pip button to be visible in portrait")
		XCTAssertEqual(sut.controlsView.fullscreenButton.alpha, 1.0, "Expected fullscreen button to be visible in portrait")
	}

	func test_fullscreenButtonTap_inLandscapeWithHiddenControls_doesNotToggleControlsVisibility() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		// Go to landscape and trigger auto-hide
		sut.simulateLandscapeOrientation()
		sut.simulateControlsAutoHide()

		// Verify controls are hidden
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 0.0, "Precondition: speed button should be hidden")

		// Tap fullscreen button - this should NOT toggle controls visibility
		// The tap should only trigger the fullscreen action, not show controls
		sut.controlsView.fullscreenButton.simulateTap()

		// Also simulate what happens if toggleControlsVisibility was incorrectly called
		// This represents the bug where tapping fullscreen also triggers toggle
		// sut.toggleControlsVisibility() // <-- This would be the bug

		// Controls should still be hidden (toggle was NOT called)
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 0.0, "Expected speed button to remain hidden - fullscreen tap should not toggle controls")
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 0.0, "Expected pip button to remain hidden - fullscreen tap should not toggle controls")
		XCTAssertEqual(sut.controlsView.fullscreenButton.alpha, 0.0, "Expected fullscreen button to remain hidden - fullscreen tap should not toggle controls")
	}

	func test_landscapeControlsHidden_shouldNotBeInteractive() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		// Go to landscape and trigger auto-hide
		sut.simulateLandscapeOrientation()
		sut.simulateControlsAutoHide()

		// When controls are hidden in landscape, buttons should not be interactive
		// This prevents accidental taps on invisible buttons
		XCTAssertFalse(sut.controlsView.fullscreenButton.isUserInteractionEnabled, "Expected fullscreen button to not be interactive when hidden")
		XCTAssertFalse(sut.controlsView.pipButton.isUserInteractionEnabled, "Expected pip button to not be interactive when hidden")
		XCTAssertFalse(sut.controlsView.playbackSpeedButton.isUserInteractionEnabled, "Expected speed button to not be interactive when hidden")
	}

	func test_landscapeControlsVisible_shouldBeInteractive() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		// Go to landscape (controls are visible initially)
		sut.simulateLandscapeOrientation()

		// When controls are visible, buttons should be interactive
		XCTAssertTrue(sut.controlsView.fullscreenButton.isUserInteractionEnabled, "Expected fullscreen button to be interactive when visible")
		XCTAssertTrue(sut.controlsView.pipButton.isUserInteractionEnabled, "Expected pip button to be interactive when visible")
		XCTAssertTrue(sut.controlsView.playbackSpeedButton.isUserInteractionEnabled, "Expected speed button to be interactive when visible")
	}

	func test_portraitAutoHide_thenFullscreenTap_hidesButtonsInLandscape() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		// Start in portrait
		sut.loadViewIfNeeded()

		// Trigger auto-hide in portrait (bottom controls stay visible, overlay hides)
		sut.simulateControlsAutoHide()

		// In portrait after auto-hide, bottom controls should still be visible
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 1.0, "Precondition: speed button visible in portrait after auto-hide")
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 1.0, "Precondition: pip button visible in portrait after auto-hide")
		XCTAssertEqual(sut.controlsView.fullscreenButton.alpha, 1.0, "Precondition: fullscreen button visible in portrait after auto-hide")

		// Now tap fullscreen to go to landscape
		sut.controlsView.fullscreenButton.simulateTap()
		sut.simulateLandscapeOrientation()

		// BUG: The buttons that were visible in portrait should be HIDDEN in landscape
		// because in landscape, all controls auto-hide together (and they should start hidden
		// since the player is playing and auto-hide was already triggered)
		XCTAssertEqual(sut.controlsView.playbackSpeedButton.alpha, 0.0, "Expected speed button to be hidden in landscape after transition from portrait with auto-hide")
		XCTAssertEqual(sut.controlsView.pipButton.alpha, 0.0, "Expected pip button to be hidden in landscape after transition from portrait with auto-hide")
		XCTAssertEqual(sut.controlsView.fullscreenButton.alpha, 0.0, "Expected fullscreen button to be hidden in landscape after transition from portrait with auto-hide")
	}

	// MARK: - Helpers

	private func makeSUT(
		video: Video = makeVideo(),
		player: VideoPlayer? = nil,
		commentsController: UIViewController? = nil,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> VideoPlayerViewController {
		let sut = VideoPlayerUIComposer.videoPlayerComposedWith(
			video: video,
			player: player,
			commentsController: commentsController
		)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func makeUnTrackedSUT(
		video: Video = makeVideo(),
		player: VideoPlayer? = nil,
		commentsController: UIViewController? = nil
	) -> VideoPlayerViewController {
		return VideoPlayerUIComposer.videoPlayerComposedWith(
			video: video,
			player: player,
			commentsController: commentsController
		)
	}

	@MainActor
	private final class VideoPlayerSpy: VideoPlayer {
		var isPlaying: Bool = false
		var currentTime: TimeInterval = 0
		var duration: TimeInterval = 100
		var volume: Float = 1.0
		var isMuted: Bool = false
		var playbackSpeed: Float = 1.0
		private(set) var loadedURLs: [URL] = []
		private(set) var playCallCount = 0
		private(set) var pauseCallCount = 0

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

		func seekForward(by seconds: TimeInterval) {}
		func seekBackward(by seconds: TimeInterval) {}
		func seek(to time: TimeInterval) {}
		func setVolume(_ volume: Float) { self.volume = volume }
		func toggleMute() { isMuted.toggle() }
		func setPlaybackSpeed(_ speed: Float) { self.playbackSpeed = speed }
	}
}

private func makeVideo(
	title: String = "any title",
	url: URL = URL(string: "https://any-url.com/video.mp4")!
) -> Video {
	Video(
		id: UUID(),
		title: title,
		description: "any description",
		url: url,
		thumbnailURL: URL(string: "https://any-thumbnail.com")!,
		duration: 120
	)
}

extension VideoPlayerViewController {
	func simulateViewDidAppear() {
		loadViewIfNeeded()
		beginAppearanceTransition(true, animated: false)
		endAppearanceTransition()
	}

	func simulateControlsAutoHide() {
		loadViewIfNeeded()
		triggerAutoHide()
	}

	func simulatePauseTriggered() {
		showControlsOnPause()
	}

	func simulateLandscapeOrientation() {
		loadViewIfNeeded()
		updateLayoutForOrientation(isLandscape: true)
	}

	func simulatePortraitOrientation() {
		loadViewIfNeeded()
		updateLayoutForOrientation(isLandscape: false)
	}

	var commentsContainerView: UIView? {
		view.subviews.first { $0.tag == 999 }
	}

	var bottomControlsContainerView: UIView? {
		view.subviews.first { $0.tag == 998 }
	}

	var isPlayerViewFullscreen: Bool {
		playerView.frame.width == view.bounds.width &&
		playerView.frame.height >= view.bounds.height * 0.9
	}

}
