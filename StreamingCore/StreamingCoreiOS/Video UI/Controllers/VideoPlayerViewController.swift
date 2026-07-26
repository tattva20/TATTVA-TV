//
//  VideoPlayerViewController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore

public final class VideoPlayerViewController: UIViewController {
	private let viewModel: VideoPlayerViewModel
	private let player: VideoPlayer

	// MARK: - Views

	public private(set) lazy var playerView: PlayerView = {
		let view = PlayerView()
		view.backgroundColor = .black
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	public private(set) lazy var controlsView = VideoPlayerControls()

	// MARK: - State

	public private(set) var isFullscreen: Bool = false
	public var areControlsVisible: Bool {
		controlsVisibilityController?.areControlsVisible ?? true
	}
	private var controlsVisibilityController: ControlsVisibilityController?
	private var controlsController: PlaybackControlsController?
	private let layoutController = PlayerLayoutController()
	private var hideControlsTimer: Timer?
	private var isLandscape: Bool = false

	// MARK: - External Callbacks

	public var onFullscreenToggle: (() -> Void)?
	public var onPipToggle: (() -> Void)?
	public var pipController: PictureInPictureControlling?

	// MARK: - Comments

	public private(set) var embeddedCommentsController: UIViewController?
	private let commentsEmbedding = CommentsEmbeddingController()

	// MARK: - Initialization

	public init(viewModel: VideoPlayerViewModel, player: VideoPlayer) {
		self.viewModel = viewModel
		self.player = player
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Lifecycle

	public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .allButUpsideDown
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		isLandscape = view.bounds.width > view.bounds.height
		updateEdgesForExtendedLayout()
		setupUI()
		setupControlsController()
		configurePlayer()
		setupControlsVisibilityController()

		if let commentsController = embeddedCommentsController {
			embedCommentsController(commentsController)
		}
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		autoPlay()
		controlsVisibilityController?.scheduleHide()
	}

	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		hideControlsTimer?.invalidate()
		if pipController?.isPictureInPictureActive != true {
			player.pause()
		}
	}

	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate { [weak self] _ in
			guard let self = self else { return }
			let newIsLandscape = size.width > size.height
			self.updateLayoutForOrientation(isLandscape: newIsLandscape)
		}
	}

	// MARK: - Setup

	private func setupUI() {
		title = viewModel.title
		view.backgroundColor = .black

		view.addSubview(playerView)
		view.addSubview(controlsView.playButton)
		view.addSubview(controlsView.seekForwardButton)
		view.addSubview(controlsView.seekBackwardButton)
		view.addSubview(controlsView.progressSlider)
		view.addSubview(controlsView.currentTimeLabel)
		view.addSubview(controlsView.durationLabel)

		view.addSubview(controlsView.bottomControlsContainer)
		controlsView.bottomControlsContainer.addSubview(controlsView.muteButton)
		controlsView.bottomControlsContainer.addSubview(controlsView.volumeSlider)

		view.addSubview(controlsView.playbackSpeedButton)
		view.addSubview(controlsView.pipButton)
		view.addSubview(controlsView.fullscreenButton)

		controlsView.setTitle(viewModel.title)
		view.addSubview(controlsView.landscapeTitleLabel)

		setupTapGesture()
		layoutController.setupConstraints(view: view, playerView: playerView, controlsView: controlsView)
	}

	private func setupControlsController() {
		controlsController = PlaybackControlsController(player: player, controlsView: controlsView, delegate: self)
	}

	private func setupTapGesture() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		playerView.addGestureRecognizer(tapGesture)
		playerView.isUserInteractionEnabled = true
	}

	private func setupControlsVisibilityController() {
		controlsVisibilityController = ControlsVisibilityController(hideDelay: 5.0, delegate: self, isVoiceOverRunning: { UIAccessibility.isVoiceOverRunning })
	}

	private func configurePlayer() {
		player.load(url: viewModel.videoURL)
	}

	// MARK: - Playback

	private func autoPlay() {
		player.play()
		controlsView.setPlayButtonPlaying(true)
	}

	private func showControlsForPause() {
		controlsVisibilityController?.cancelTimer()
		if !areControlsVisible {
			controlsVisibilityController?.show()
		}
	}

	// MARK: - Tap Handling

	@objc private func handleTap() {
		toggleControlsVisibility()
	}

	public func toggleControlsVisibility() {
		controlsVisibilityController?.toggle()
	}

	public func triggerAutoHide() {
		guard player.isPlaying else { return }
		controlsView.setControlsAlpha(0.0, isLandscape: isLandscape)
		controlsVisibilityController?.hide()
	}

	public func showControlsOnPause() {
		controlsVisibilityController?.cancelTimer()
		controlsView.setControlsAlpha(1.0, isLandscape: isLandscape)
	}

	// MARK: - Time Display

	public func updateTimeDisplay() {
		let current = VideoPlayerPresenter.formatTime(player.currentTime)
		let duration = VideoPlayerPresenter.formatTime(player.duration)
		let progress = player.duration > 0 ? Float(player.currentTime / player.duration) : 0
		controlsView.updateTime(current: current, duration: duration, progress: progress)
	}

	// MARK: - Comments

	public func setCommentsController(_ controller: UIViewController) {
		embeddedCommentsController = controller
		if isViewLoaded {
			embedCommentsController(controller)
		}
	}

	private func embedCommentsController(_ controller: UIViewController) {
		guard !commentsEmbedding.isEmbedded else { return }
		commentsEmbedding.embed(controller, in: self, below: controlsView.bottomControlsContainer, isLandscape: isLandscape)
		updateLayoutForOrientation(isLandscape: isLandscape)
	}

	// MARK: - Layout

	private func updateEdgesForExtendedLayout() {
		edgesForExtendedLayout = isLandscape ? .all : []
	}

	public func updateLayoutForOrientation(isLandscape: Bool) {
		self.isLandscape = isLandscape
		self.isFullscreen = isLandscape
		updateEdgesForExtendedLayout()
		controlsView.setFullscreenButtonExpanded(isFullscreen)

		layoutController.apply(isLandscape: isLandscape)
		commentsEmbedding.setVisible(!isLandscape)

		if isLandscape {
			controlsView.updateLayout(for: .landscape)
			navigationController?.setNavigationBarHidden(true, animated: true)

			if !areControlsVisible {
				controlsView.setControlsAlpha(0.0, isLandscape: true)
				controlsView.setLandscapeControlsInteraction(enabled: false)
			}
		} else {
			controlsView.updateLayout(for: .portrait)
			navigationController?.setNavigationBarHidden(false, animated: true)
		}

		view.layoutIfNeeded()

		if !isLandscape {
			controlsView.clearPendingAnimations()
			controlsView.playbackSpeedButton.alpha = 1.0
			controlsView.pipButton.alpha = 1.0
			controlsView.fullscreenButton.alpha = 1.0
			controlsView.setLandscapeControlsInteraction(enabled: true)
		}
	}

}

// MARK: - PlaybackControlsControllerDelegate

extension VideoPlayerViewController: PlaybackControlsControllerDelegate {
	public func playbackControlsDidInteract() {
		controlsVisibilityController?.scheduleHide()
	}

	public func playbackControlsDidPause() {
		showControlsForPause()
	}

	public func playbackControlsDidToggleFullscreen() {
		onFullscreenToggle?()
	}

	public func playbackControlsDidTogglePictureInPicture() {
		onPipToggle?()
	}
}

// MARK: - ControlsVisibilityDelegate

extension VideoPlayerViewController: ControlsVisibilityDelegate {
	public func controlsDidShow() {
		controlsView.animateControlsVisible(isLandscape: isLandscape)
	}

	public func controlsDidHide() {
		guard player.isPlaying else { return }
		controlsView.animateControlsHidden(isLandscape: isLandscape)
	}

	public func scheduleTimer(withDelay delay: TimeInterval, callback: @escaping @MainActor () -> Void) {
		hideControlsTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
			MainActor.assumeIsolated {
				guard self?.player.isPlaying == true else { return }
				callback()
			}
		}
	}

	public func cancelTimer() {
		hideControlsTimer?.invalidate()
	}
}
