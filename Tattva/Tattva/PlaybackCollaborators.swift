//
//  PlaybackCollaborators.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Combine
import UIKit
import StreamingCoreiOS
import StreamingCorePlayback

final class PlaybackCollaborators {
	let statefulPlayer: StatefulVideoPlayer
	let performanceAdapter: VideoPlayerPerformanceAdapter
	let playbackCoordinator: PlaybackCoordinator?
	let bufferAdapter: AVPlayerBufferAdapterConcrete?
	let networkBitrateBinding: NetworkBitrateBinding?
	let performanceAlertLogging: PerformanceAlertLoggingBinding?
	let memoryPerformanceCancellable: AnyCancellable?

	init(
		statefulPlayer: StatefulVideoPlayer,
		performanceAdapter: VideoPlayerPerformanceAdapter,
		playbackCoordinator: PlaybackCoordinator? = nil,
		bufferAdapter: AVPlayerBufferAdapterConcrete? = nil,
		networkBitrateBinding: NetworkBitrateBinding? = nil,
		performanceAlertLogging: PerformanceAlertLoggingBinding? = nil,
		memoryPerformanceCancellable: AnyCancellable? = nil
	) {
		self.statefulPlayer = statefulPlayer
		self.performanceAdapter = performanceAdapter
		self.playbackCoordinator = playbackCoordinator
		self.bufferAdapter = bufferAdapter
		self.networkBitrateBinding = networkBitrateBinding
		self.performanceAlertLogging = performanceAlertLogging
		self.memoryPerformanceCancellable = memoryPerformanceCancellable
	}
}

private nonisolated(unsafe) var playbackCollaboratorsKey: UInt8 = 0

extension VideoPlayerViewController {
	var playbackCollaborators: PlaybackCollaborators? {
		get {
			objc_getAssociatedObject(self, &playbackCollaboratorsKey) as? PlaybackCollaborators
		}
		set {
			objc_setAssociatedObject(
				self,
				&playbackCollaboratorsKey,
				newValue,
				.OBJC_ASSOCIATION_RETAIN_NONATOMIC
			)
		}
	}
}
