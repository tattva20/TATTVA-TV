//
//  PlaybackControlsController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import StreamingCore

@MainActor
public protocol PlaybackControlsControllerDelegate: AnyObject {
	func playbackControlsDidInteract()
	func playbackControlsDidPause()
	func playbackControlsDidToggleFullscreen()
	func playbackControlsDidTogglePictureInPicture()
}

@MainActor
public final class PlaybackControlsController {
	private let player: VideoPlayer
	private let controlsView: VideoPlayerControls
	private weak var delegate: PlaybackControlsControllerDelegate?

	private static let playbackSpeeds: [Float] = [1.0, 1.25, 1.5, 2.0, 0.5]

	public init(player: VideoPlayer, controlsView: VideoPlayerControls, delegate: PlaybackControlsControllerDelegate) {
		self.player = player
		self.controlsView = controlsView
		self.delegate = delegate
		configureCallbacks()
	}

	private func configureCallbacks() {
		controlsView.onPlayTapped = { [weak self] in self?.handlePlayTapped() }
		controlsView.onSeekForwardTapped = { [weak self] in self?.handleSeekForwardTapped() }
		controlsView.onSeekBackwardTapped = { [weak self] in self?.handleSeekBackwardTapped() }
		controlsView.onProgressChanged = { [weak self] in self?.handleProgressChanged($0) }
		controlsView.onMuteTapped = { [weak self] in self?.handleMuteTapped() }
		controlsView.onVolumeChanged = { [weak self] in self?.handleVolumeChanged($0) }
		controlsView.onSpeedTapped = { [weak self] in self?.handleSpeedTapped() }
		controlsView.onFullscreenTapped = { [weak self] in self?.delegate?.playbackControlsDidToggleFullscreen() }
		controlsView.onPipTapped = { [weak self] in self?.delegate?.playbackControlsDidTogglePictureInPicture() }
	}

	private func handlePlayTapped() {
		if player.isPlaying {
			player.pause()
			controlsView.setPlayButtonPlaying(false)
			delegate?.playbackControlsDidPause()
		} else {
			player.play()
			controlsView.setPlayButtonPlaying(true)
			delegate?.playbackControlsDidInteract()
		}
	}

	private func handleSeekForwardTapped() {
		delegate?.playbackControlsDidInteract()
		player.seekForward(by: 10)
	}

	private func handleSeekBackwardTapped() {
		delegate?.playbackControlsDidInteract()
		player.seekBackward(by: 10)
	}

	private func handleProgressChanged(_ value: Float) {
		delegate?.playbackControlsDidInteract()
		let targetTime = TimeInterval(value) * player.duration
		player.seek(to: targetTime)
	}

	private func handleMuteTapped() {
		player.toggleMute()
		controlsView.setMuteButtonMuted(player.isMuted)
	}

	private func handleVolumeChanged(_ value: Float) {
		player.setVolume(value)
	}

	private func handleSpeedTapped() {
		let currentSpeed = player.playbackSpeed
		let currentIndex = Self.playbackSpeeds.firstIndex(of: currentSpeed) ?? 0
		let nextIndex = (currentIndex + 1) % Self.playbackSpeeds.count
		let newSpeed = Self.playbackSpeeds[nextIndex]
		player.setPlaybackSpeed(newSpeed)
		updatePlaybackSpeedButtonTitle()
	}

	private func updatePlaybackSpeedButtonTitle() {
		let speed = player.playbackSpeed
		let title = speed == 1.0 ? "1x" : String(format: "%.2gx", speed)
		controlsView.setSpeedButtonTitle(title)
	}
}
