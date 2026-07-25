//
//  PlayerLayoutControllerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import UIKit
import StreamingCoreiOS

@MainActor
final class PlayerLayoutControllerTests: XCTestCase {

	func test_portrait_constrainsPlayerViewToSixteenNineAspectRatio() {
		let (sut, host, playerView, controlsView) = makeSUT()
		sut.setupConstraints(view: host, playerView: playerView, controlsView: controlsView)

		sut.apply(isLandscape: false)
		host.layoutIfNeeded()

		XCTAssertEqual(playerView.frame.height, playerView.frame.width * 9.0 / 16.0, accuracy: 1.0)
		XCTAssertLessThan(playerView.frame.height, host.bounds.height, "Portrait player should not fill the tall container")
	}

	func test_landscape_makesPlayerViewFillTheContainer() {
		let (sut, host, playerView, controlsView) = makeSUT()
		sut.setupConstraints(view: host, playerView: playerView, controlsView: controlsView)

		sut.apply(isLandscape: true)
		host.layoutIfNeeded()

		XCTAssertEqual(playerView.frame, host.bounds, "Landscape player should fill the container")
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: PlayerLayoutController, host: UIView, playerView: UIView, controlsView: VideoPlayerControlsView) {
		let sut = PlayerLayoutController()
		let host = UIView(frame: CGRect(x: 0, y: 0, width: 1080, height: 1920))
		let playerView = UIView()
		playerView.translatesAutoresizingMaskIntoConstraints = false
		let controlsView = VideoPlayerControlsView()

		host.addSubview(playerView)
		host.addSubview(controlsView.playButton)
		host.addSubview(controlsView.seekForwardButton)
		host.addSubview(controlsView.seekBackwardButton)
		host.addSubview(controlsView.progressSlider)
		host.addSubview(controlsView.currentTimeLabel)
		host.addSubview(controlsView.durationLabel)
		host.addSubview(controlsView.bottomControlsContainer)
		controlsView.bottomControlsContainer.addSubview(controlsView.muteButton)
		controlsView.bottomControlsContainer.addSubview(controlsView.volumeSlider)
		host.addSubview(controlsView.playbackSpeedButton)
		host.addSubview(controlsView.pipButton)
		host.addSubview(controlsView.fullscreenButton)
		host.addSubview(controlsView.landscapeTitleLabel)

		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, host, playerView, controlsView)
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}
}
