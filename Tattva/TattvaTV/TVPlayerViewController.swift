import AVKit
import UIKit
import StreamingCore
import StreamingCorePlayback

@MainActor
public final class TVPlayerViewController: AVPlayerViewController {
	private let video: Video
	private let infoViewController: UIViewController?
	private let analyticsLogger: PlaybackAnalyticsLogger?
	private let structuredLogger: (any StreamingCore.Logger)?
	private let bufferManager: (any BufferManager)?
	private var playbackBundle: TVPlayerComposer.Bundle?

	public init(
		video: Video,
		infoViewController: UIViewController? = nil,
		analyticsLogger: PlaybackAnalyticsLogger? = nil,
		structuredLogger: (any StreamingCore.Logger)? = nil,
		bufferManager: (any BufferManager)? = nil
	) {
		self.video = video
		self.infoViewController = infoViewController
		self.analyticsLogger = analyticsLogger
		self.structuredLogger = structuredLogger
		self.bufferManager = bufferManager
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		let bundle = TVPlayerComposer.playerComposedWith(
			video: video,
			analyticsLogger: analyticsLogger,
			structuredLogger: structuredLogger,
			bufferManager: bufferManager
		)
		player = bundle.player
		playbackBundle = bundle

		configureAdvancedControls()

		if let infoViewController {
			customInfoViewControllers = [infoViewController]
		}
	}

	private func configureAdvancedControls() {
		speeds = Self.playbackSpeeds
		transportBarCustomMenuItems = [makeRestartAction()]
	}

	private func makeRestartAction() -> UIMenuElement {
		UIAction(title: "Restart", image: UIImage(systemName: "gobackward")) { [weak self] _ in
			self?.player?.seek(to: .zero)
		}
	}

	private static let playbackSpeeds: [AVPlaybackSpeed] = [
		AVPlaybackSpeed(rate: 0.5, localizedName: "0.5×"),
		AVPlaybackSpeed(rate: 1.0, localizedName: "1×"),
		AVPlaybackSpeed(rate: 1.25, localizedName: "1.25×"),
		AVPlaybackSpeed(rate: 1.5, localizedName: "1.5×"),
		AVPlaybackSpeed(rate: 2.0, localizedName: "2×")
	]

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		playbackBundle?.statefulPlayer.play()
	}

	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		playbackBundle?.statefulPlayer.pause()
	}

	public override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		playbackBundle?.coordinator.stop()
	}
}
