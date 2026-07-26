//
//  PlayerLayoutController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit

@MainActor
public final class PlayerLayoutController {
	private var portraitConstraints: [NSLayoutConstraint] = []
	private var landscapeConstraints: [NSLayoutConstraint] = []
	private var bottomControlsContainerConstraints: [NSLayoutConstraint] = []
	private var fullscreenButtonPortraitConstraints: [NSLayoutConstraint] = []
	private var fullscreenButtonLandscapeConstraints: [NSLayoutConstraint] = []
	private var pipButtonPortraitConstraints: [NSLayoutConstraint] = []
	private var pipButtonLandscapeConstraints: [NSLayoutConstraint] = []
	private var playbackSpeedButtonPortraitConstraints: [NSLayoutConstraint] = []
	private var playbackSpeedButtonLandscapeConstraints: [NSLayoutConstraint] = []
	private var durationLabelPortraitConstraint: NSLayoutConstraint?
	private var durationLabelLandscapeConstraint: NSLayoutConstraint?
	private var currentTimeLabelBottomPortraitConstraint: NSLayoutConstraint?
	private var currentTimeLabelBottomLandscapeConstraint: NSLayoutConstraint?
	private var durationLabelBottomPortraitConstraint: NSLayoutConstraint?
	private var durationLabelBottomLandscapeConstraint: NSLayoutConstraint?
	private var currentTimeLabelLeadingPortraitConstraint: NSLayoutConstraint?
	private var currentTimeLabelLeadingLandscapeConstraint: NSLayoutConstraint?

	public init() {}

	public func setupConstraints(view: UIView, playerView: UIView, controlsView: VideoPlayerControls) {
		let playerViewAspectRatio = playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9.0/16.0)

		portraitConstraints = [
			playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			playerViewAspectRatio
		]

		landscapeConstraints = [
			playerView.topAnchor.constraint(equalTo: view.topAnchor),
			playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		]

		durationLabelPortraitConstraint = controlsView.durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
		durationLabelLandscapeConstraint = controlsView.durationLabel.trailingAnchor.constraint(equalTo: controlsView.playbackSpeedButton.leadingAnchor, constant: -8)

		currentTimeLabelBottomPortraitConstraint = controlsView.currentTimeLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16)
		currentTimeLabelBottomLandscapeConstraint = controlsView.currentTimeLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -64)
		durationLabelBottomPortraitConstraint = controlsView.durationLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16)
		durationLabelBottomLandscapeConstraint = controlsView.durationLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -64)

		currentTimeLabelLeadingPortraitConstraint = controlsView.currentTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
		currentTimeLabelLeadingLandscapeConstraint = controlsView.currentTimeLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24)

		pipButtonPortraitConstraints = [
			controlsView.pipButton.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.pipButton.trailingAnchor.constraint(equalTo: controlsView.fullscreenButton.leadingAnchor, constant: -8)
		]

		pipButtonLandscapeConstraints = [
			controlsView.pipButton.centerYAnchor.constraint(equalTo: controlsView.durationLabel.centerYAnchor),
			controlsView.pipButton.trailingAnchor.constraint(equalTo: controlsView.fullscreenButton.leadingAnchor, constant: -8)
		]

		fullscreenButtonPortraitConstraints = [
			controlsView.fullscreenButton.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.fullscreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
		]

		fullscreenButtonLandscapeConstraints = [
			controlsView.fullscreenButton.centerYAnchor.constraint(equalTo: controlsView.durationLabel.centerYAnchor),
			controlsView.fullscreenButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
		]

		playbackSpeedButtonPortraitConstraints = [
			controlsView.playbackSpeedButton.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.playbackSpeedButton.trailingAnchor.constraint(equalTo: controlsView.pipButton.leadingAnchor, constant: -8)
		]

		playbackSpeedButtonLandscapeConstraints = [
			controlsView.playbackSpeedButton.centerYAnchor.constraint(equalTo: controlsView.durationLabel.centerYAnchor),
			controlsView.playbackSpeedButton.trailingAnchor.constraint(equalTo: controlsView.pipButton.leadingAnchor, constant: -8)
		]

		bottomControlsContainerConstraints = [
			controlsView.bottomControlsContainer.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 16),
			controlsView.bottomControlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			controlsView.bottomControlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			controlsView.bottomControlsContainer.heightAnchor.constraint(equalToConstant: 44)
		]

		NSLayoutConstraint.activate([
			controlsView.playButton.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
			controlsView.playButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			controlsView.playButton.widthAnchor.constraint(equalToConstant: 60),
			controlsView.playButton.heightAnchor.constraint(equalToConstant: 60),

			controlsView.seekBackwardButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			controlsView.seekBackwardButton.trailingAnchor.constraint(equalTo: controlsView.playButton.leadingAnchor, constant: -40),
			controlsView.seekBackwardButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.seekBackwardButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.seekForwardButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			controlsView.seekForwardButton.leadingAnchor.constraint(equalTo: controlsView.playButton.trailingAnchor, constant: 40),
			controlsView.seekForwardButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.seekForwardButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.progressSlider.leadingAnchor.constraint(equalTo: controlsView.currentTimeLabel.trailingAnchor, constant: 8),
			controlsView.progressSlider.trailingAnchor.constraint(equalTo: controlsView.durationLabel.leadingAnchor, constant: -8),
			controlsView.progressSlider.centerYAnchor.constraint(equalTo: controlsView.currentTimeLabel.centerYAnchor),

			controlsView.muteButton.leadingAnchor.constraint(equalTo: controlsView.bottomControlsContainer.leadingAnchor, constant: 16),
			controlsView.muteButton.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.muteButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.muteButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.volumeSlider.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.volumeSlider.leadingAnchor.constraint(equalTo: controlsView.muteButton.trailingAnchor, constant: 8),
			controlsView.volumeSlider.widthAnchor.constraint(equalToConstant: 100),

			controlsView.playbackSpeedButton.widthAnchor.constraint(equalToConstant: 50),

			controlsView.pipButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.pipButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.fullscreenButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.fullscreenButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.landscapeTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
			controlsView.landscapeTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			controlsView.landscapeTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
			controlsView.landscapeTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
		])

		NSLayoutConstraint.activate(portraitConstraints)
		NSLayoutConstraint.activate(fullscreenButtonPortraitConstraints)
		NSLayoutConstraint.activate(pipButtonPortraitConstraints)
		NSLayoutConstraint.activate(playbackSpeedButtonPortraitConstraints)
		NSLayoutConstraint.activate(bottomControlsContainerConstraints)
		durationLabelPortraitConstraint?.isActive = true
		currentTimeLabelBottomPortraitConstraint?.isActive = true
		durationLabelBottomPortraitConstraint?.isActive = true
		currentTimeLabelLeadingPortraitConstraint?.isActive = true
	}

	public func apply(isLandscape: Bool) {
		if isLandscape {
			NSLayoutConstraint.deactivate(portraitConstraints)
			NSLayoutConstraint.deactivate(fullscreenButtonPortraitConstraints)
			NSLayoutConstraint.deactivate(pipButtonPortraitConstraints)
			NSLayoutConstraint.deactivate(playbackSpeedButtonPortraitConstraints)
			NSLayoutConstraint.deactivate(bottomControlsContainerConstraints)
			durationLabelPortraitConstraint?.isActive = false
			currentTimeLabelBottomPortraitConstraint?.isActive = false
			durationLabelBottomPortraitConstraint?.isActive = false
			currentTimeLabelLeadingPortraitConstraint?.isActive = false

			NSLayoutConstraint.activate(landscapeConstraints)
			NSLayoutConstraint.activate(fullscreenButtonLandscapeConstraints)
			NSLayoutConstraint.activate(pipButtonLandscapeConstraints)
			NSLayoutConstraint.activate(playbackSpeedButtonLandscapeConstraints)
			durationLabelLandscapeConstraint?.isActive = true
			currentTimeLabelBottomLandscapeConstraint?.isActive = true
			durationLabelBottomLandscapeConstraint?.isActive = true
			currentTimeLabelLeadingLandscapeConstraint?.isActive = true
		} else {
			NSLayoutConstraint.deactivate(landscapeConstraints)
			NSLayoutConstraint.deactivate(fullscreenButtonLandscapeConstraints)
			NSLayoutConstraint.deactivate(pipButtonLandscapeConstraints)
			NSLayoutConstraint.deactivate(playbackSpeedButtonLandscapeConstraints)
			durationLabelLandscapeConstraint?.isActive = false
			currentTimeLabelBottomLandscapeConstraint?.isActive = false
			durationLabelBottomLandscapeConstraint?.isActive = false
			currentTimeLabelLeadingLandscapeConstraint?.isActive = false

			NSLayoutConstraint.activate(portraitConstraints)
			NSLayoutConstraint.activate(fullscreenButtonPortraitConstraints)
			NSLayoutConstraint.activate(pipButtonPortraitConstraints)
			NSLayoutConstraint.activate(playbackSpeedButtonPortraitConstraints)
			NSLayoutConstraint.activate(bottomControlsContainerConstraints)
			durationLabelPortraitConstraint?.isActive = true
			currentTimeLabelBottomPortraitConstraint?.isActive = true
			durationLabelBottomPortraitConstraint?.isActive = true
			currentTimeLabelLeadingPortraitConstraint?.isActive = true
		}
	}
}
