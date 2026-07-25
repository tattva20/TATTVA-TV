//
//  AVPlayerVideoPlayer.swift
//  StreamingCorePlayback
//
//  Copyright by Octavio Rojas all rights reserved.
//
import AVFoundation
import StreamingCore

public final class AVPlayerVideoPlayer: VideoPlayer {
	public let player: AVPlayer

	public var isPlaying: Bool = false
	public var isMuted: Bool = false

	public var currentTime: TimeInterval {
		let seconds = player.currentTime().seconds
		return seconds.isFinite ? seconds : 0
	}

	public var duration: TimeInterval {
		guard let seconds = player.currentItem?.duration.seconds, seconds.isFinite else {
			return 0
		}
		return seconds
	}

	public var volume: Float {
		player.volume
	}

	public var playbackSpeed: Float = 1.0

	public init(player: AVPlayer = AVPlayer()) {
		self.player = player
		player.automaticallyWaitsToMinimizeStalling = true
	}

	public func load(url: URL) {
		let playerItem = AVPlayerItem(url: url)
		player.replaceCurrentItem(with: playerItem)
	}

	public func play() {
		player.play()
		isPlaying = true
	}

	public func pause() {
		player.pause()
		isPlaying = false
	}

	public func seekForward(by seconds: TimeInterval) {
		let newTime = currentTime + seconds
		seek(to: min(newTime, duration))
	}

	public func seekBackward(by seconds: TimeInterval) {
		let newTime = currentTime - seconds
		seek(to: max(newTime, 0))
	}

	public func seek(to time: TimeInterval) {
		let cmTime = CMTime(seconds: time, preferredTimescale: 600)
		player.seek(to: cmTime)
	}

	public func setVolume(_ volume: Float) {
		player.volume = volume
	}

	public func toggleMute() {
		isMuted.toggle()
		player.isMuted = isMuted
	}

	public func setPlaybackSpeed(_ speed: Float) {
		playbackSpeed = speed
		player.rate = speed
	}
}
