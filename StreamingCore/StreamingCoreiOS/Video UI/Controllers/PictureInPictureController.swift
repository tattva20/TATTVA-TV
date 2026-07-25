//
//  PictureInPictureController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVKit

@MainActor
public final class PictureInPictureController: NSObject, PictureInPictureControlling {
	private var pipController: AVPictureInPictureController?
	private weak var playerView: PlayerView?

	public var onRestoreUserInterface: ((@escaping (Bool) -> Void) -> Void)?

	public var isPictureInPictureActive: Bool {
		pipController?.isPictureInPictureActive ?? false
	}

	public var isPictureInPicturePossible: Bool {
		pipController?.isPictureInPicturePossible ?? false
	}

	public func setup(with playerView: PlayerView) {
		guard AVPictureInPictureController.isPictureInPictureSupported() else { return }

		self.playerView = playerView
		pipController = AVPictureInPictureController(playerLayer: playerView.playerLayer)
		pipController?.delegate = self
		pipController?.canStartPictureInPictureAutomaticallyFromInline = true
	}

	public func togglePictureInPicture() {
		guard let pipController = pipController else { return }

		if pipController.isPictureInPictureActive {
			pipController.stopPictureInPicture()
		} else if pipController.isPictureInPicturePossible {
			pipController.startPictureInPicture()
		}
	}

	public func startPictureInPicture() {
		guard let pipController = pipController,
			  pipController.isPictureInPicturePossible else { return }
		pipController.startPictureInPicture()
	}

	public func stopPictureInPicture() {
		pipController?.stopPictureInPicture()
	}

	func restoreUserInterface(completion: @escaping (Bool) -> Void) {
		if let onRestoreUserInterface {
			onRestoreUserInterface(completion)
		} else {
			completion(true)
		}
	}
}

extension PictureInPictureController: AVPictureInPictureControllerDelegate {
	public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		// PiP is about to start
	}

	public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		// PiP has started
	}

	public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		// PiP is about to stop
	}

	public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		// PiP has stopped
	}

	public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
		// Handle PiP start failure
	}

	public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
		restoreUserInterface(completion: completionHandler)
	}
}
