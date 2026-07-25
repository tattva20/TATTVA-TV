//
//  AVPlayerVideoPlayerTests.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import AVFoundation
import XCTest
@testable import Tattva
@testable import StreamingCorePlayback

@MainActor
final class AVPlayerVideoPlayerTests: XCTestCase {
	func test_duration_isFiniteWhenItemDurationIsIndefinite() {
		let item = AVPlayerItem(url: anyURL())
		let sut = AVPlayerVideoPlayer(player: AVPlayer(playerItem: item))

		XCTAssertTrue(sut.duration.isFinite)
		XCTAssertEqual(sut.duration, 0)
	}

	func test_currentTime_isFiniteForFreshPlayer() {
		let sut = AVPlayerVideoPlayer()

		XCTAssertTrue(sut.currentTime.isFinite)
	}

	func test_init_setsAutomaticallyWaitsToMinimizeStalling() {
		let sut = AVPlayerVideoPlayer()

		XCTAssertTrue(sut.player.automaticallyWaitsToMinimizeStalling, "Expected deliberate stall-avoidance rather than the silently-inherited default")
	}

	func test_reload_recreatesItemFromTheLoadedURL() {
		let sut = AVPlayerVideoPlayer()
		let url = anyURL()
		sut.load(url: url)

		sut.reload()

		let reloadedURL = (sut.player.currentItem?.asset as? AVURLAsset)?.url
		XCTAssertEqual(reloadedURL, url, "Expected reload to build a fresh item from the last loaded URL")
	}

	func test_reload_withoutAPriorLoad_isANoOp() {
		let sut = AVPlayerVideoPlayer()

		sut.reload()

		XCTAssertNil(sut.player.currentItem, "Expected no item when reloading before any load")
	}

	// MARK: - Helpers

	private func anyURL() -> URL {
		URL(string: "https://any-url.com/video.mp4")!
	}
}
