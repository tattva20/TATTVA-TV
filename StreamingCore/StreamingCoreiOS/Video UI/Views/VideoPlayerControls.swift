//
//  VideoPlayerControls.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import UIKit
import StreamingCore
import StreamingCoreAccessibility

@MainActor
public final class VideoPlayerControls: NSObject {

	// MARK: - Orientation

	public enum Orientation {
		case portrait
		case landscape
	}

	// MARK: - UI Elements

	public private(set) lazy var playButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "play.fill"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var seekForwardButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "goforward.10"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(seekForwardButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var seekBackwardButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(seekBackwardButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var progressSlider: UISlider = {
		let slider = UISlider()
		slider.minimumValue = 0
		slider.maximumValue = 1
		slider.minimumTrackTintColor = .white
		slider.maximumTrackTintColor = .gray
		slider.addTarget(self, action: #selector(progressSliderValueChanged), for: .valueChanged)
		slider.translatesAutoresizingMaskIntoConstraints = false
		return slider
	}()

	public private(set) lazy var currentTimeLabel: UILabel = {
		let label = UILabel()
		label.textColor = .white
		label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
		label.text = "0:00"
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	public private(set) lazy var durationLabel: UILabel = {
		let label = UILabel()
		label.textColor = .white
		label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
		label.text = "0:00"
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	public private(set) lazy var muteButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var volumeSlider: UISlider = {
		let slider = UISlider()
		slider.minimumValue = 0
		slider.maximumValue = 1
		slider.value = 1
		slider.minimumTrackTintColor = .white
		slider.maximumTrackTintColor = .gray
		slider.addTarget(self, action: #selector(volumeSliderValueChanged), for: .valueChanged)
		slider.translatesAutoresizingMaskIntoConstraints = false
		return slider
	}()

	public private(set) lazy var playbackSpeedButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("1x", for: .normal)
		button.setTitleColor(.white, for: .normal)
		button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
		button.addTarget(self, action: #selector(playbackSpeedButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var fullscreenButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(fullscreenButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var pipButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "pip.enter"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(pipButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var landscapeTitleLabel: UILabel = {
		let label = UILabel()
		label.textColor = UIColor.white.withAlphaComponent(0.7)
		label.font = .systemFont(ofSize: 16, weight: .medium)
		label.translatesAutoresizingMaskIntoConstraints = false
		label.isHidden = true
		return label
	}()

	public private(set) lazy var bottomControlsContainer: UIView = {
		let view = UIView()
		view.tag = 998
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	// MARK: - Callbacks

	public var onPlayTapped: (() -> Void)?
	public var onSeekForwardTapped: (() -> Void)?
	public var onSeekBackwardTapped: (() -> Void)?
	public var onProgressChanged: ((Float) -> Void)?
	public var onMuteTapped: (() -> Void)?
	public var onVolumeChanged: ((Float) -> Void)?
	public var onSpeedTapped: (() -> Void)?
	public var onFullscreenTapped: (() -> Void)?
	public var onPipTapped: (() -> Void)?

	// MARK: - State

	private var currentOrientation: Orientation = .portrait

	// MARK: - Initialization

	public override init() {
		super.init()
		configureAccessibility()
	}

	// MARK: - Setup

	private func configureAccessibility() {
		playButton.accessible(label: "Play", role: .button)
		seekForwardButton.accessible(label: "Skip forward 10 seconds", role: .button)
		seekBackwardButton.accessible(label: "Skip back 10 seconds", role: .button)
		muteButton.accessible(label: "Mute", role: .button)
		playbackSpeedButton.accessible(label: "Playback speed", role: .button)
		fullscreenButton.accessible(label: "Enter full screen", role: .button)
		pipButton.accessible(label: "Picture in Picture", role: .button)
		progressSlider.accessible(label: "Playback position", role: .adjustable)
		volumeSlider.accessible(label: "Volume", role: .adjustable)
	}

	// MARK: - State Updates

	public func setPlayButtonPlaying(_ isPlaying: Bool) {
		let icon = isPlaying ? "pause.fill" : "play.fill"
		playButton.setImage(UIImage(systemName: icon), for: .normal)
		playButton.accessible(label: isPlaying ? "Pause" : "Play", role: .button)
	}

	public func setMuteButtonMuted(_ isMuted: Bool) {
		let icon = isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
		muteButton.setImage(UIImage(systemName: icon), for: .normal)
		muteButton.accessible(label: isMuted ? "Unmute" : "Mute", role: .button)
	}

	public func setFullscreenButtonExpanded(_ isExpanded: Bool) {
		let icon = isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
		fullscreenButton.setImage(UIImage(systemName: icon), for: .normal)
		fullscreenButton.accessible(label: isExpanded ? "Exit full screen" : "Enter full screen", role: .button)
	}

	public func setSpeedButtonTitle(_ title: String) {
		playbackSpeedButton.setTitle(title, for: .normal)
		playbackSpeedButton.accessible(label: "Playback speed", value: title, role: .button)
	}

	public func updateTime(current: String, duration: String, progress: Float) {
		currentTimeLabel.text = current
		durationLabel.text = duration
		progressSlider.value = progress
		progressSlider.accessible(label: "Playback position", value: "\(current) of \(duration)", role: .adjustable)
	}

	public func setTitle(_ title: String) {
		landscapeTitleLabel.text = title
		landscapeTitleLabel.textAlignment = .center
	}

	// MARK: - Layout

	public func updateLayout(for orientation: Orientation) {
		currentOrientation = orientation

		switch orientation {
		case .portrait:
			bottomControlsContainer.isHidden = false
			landscapeTitleLabel.isHidden = true
		case .landscape:
			bottomControlsContainer.isHidden = true
			landscapeTitleLabel.isHidden = false
		}
	}

	// MARK: - Controls Alpha

	public func setControlsAlpha(_ alpha: CGFloat, isLandscape: Bool) {
		// Overlay controls - always affected in both orientations
		playButton.alpha = alpha
		seekForwardButton.alpha = alpha
		seekBackwardButton.alpha = alpha
		progressSlider.alpha = alpha
		currentTimeLabel.alpha = alpha
		durationLabel.alpha = alpha

		if isLandscape {
			// In landscape, ALL controls auto-hide together
			muteButton.alpha = alpha
			volumeSlider.alpha = alpha
			playbackSpeedButton.alpha = alpha
			pipButton.alpha = alpha
			fullscreenButton.alpha = alpha
			landscapeTitleLabel.alpha = alpha
		} else if alpha == 1.0 {
			// In portrait, ALWAYS restore bottom controls when showing
			playbackSpeedButton.alpha = 1.0
			pipButton.alpha = 1.0
			fullscreenButton.alpha = 1.0
		}
		// Note: In portrait when hiding (alpha == 0), we don't touch bottom controls
		// They should always remain visible in portrait mode
	}

	// MARK: - Interaction State

	public func setLandscapeControlsInteraction(enabled: Bool) {
		playbackSpeedButton.isUserInteractionEnabled = enabled
		pipButton.isUserInteractionEnabled = enabled
		fullscreenButton.isUserInteractionEnabled = enabled
	}

	public func clearPendingAnimations() {
		playbackSpeedButton.layer.removeAllAnimations()
		pipButton.layer.removeAllAnimations()
		fullscreenButton.layer.removeAllAnimations()
	}

	// MARK: - Controls Visibility Animation

	public func animateControlsVisible(isLandscape: Bool) {
		if isLandscape {
			setLandscapeControlsInteraction(enabled: true)
		}
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.setControlsAlpha(1.0, isLandscape: isLandscape)
		}
	}

	public func animateControlsHidden(isLandscape: Bool) {
		if isLandscape {
			setLandscapeControlsInteraction(enabled: false)
		}
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.setControlsAlpha(0.0, isLandscape: isLandscape)
		}
	}

	// MARK: - Actions

	@objc private func playButtonTapped() {
		onPlayTapped?()
	}

	@objc private func seekForwardButtonTapped() {
		onSeekForwardTapped?()
	}

	@objc private func seekBackwardButtonTapped() {
		onSeekBackwardTapped?()
	}

	@objc private func progressSliderValueChanged() {
		onProgressChanged?(progressSlider.value)
	}

	@objc private func muteButtonTapped() {
		onMuteTapped?()
	}

	@objc private func volumeSliderValueChanged() {
		onVolumeChanged?(volumeSlider.value)
	}

	@objc private func playbackSpeedButtonTapped() {
		onSpeedTapped?()
	}

	@objc private func fullscreenButtonTapped() {
		onFullscreenTapped?()
	}

	@objc private func pipButtonTapped() {
		onPipTapped?()
	}
}
