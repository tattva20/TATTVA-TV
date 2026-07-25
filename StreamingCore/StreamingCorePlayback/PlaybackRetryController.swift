//
//  PlaybackRetryController.swift
//  StreamingCorePlayback
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

@MainActor
public final class PlaybackRetryController {
	private let maxAttempts: Int
	private let baseDelay: TimeInterval
	private let schedule: (TimeInterval, @escaping @MainActor () -> Void) -> Void
	private let reload: () -> Void

	private(set) var attempts = 0

	public init(
		maxAttempts: Int = 3,
		baseDelay: TimeInterval = 1,
		schedule: @escaping (TimeInterval, @escaping @MainActor () -> Void) -> Void = PlaybackRetryController.liveSchedule,
		reload: @escaping () -> Void
	) {
		self.maxAttempts = maxAttempts
		self.baseDelay = baseDelay
		self.schedule = schedule
		self.reload = reload
	}

	public func playbackDidFail() {
		guard attempts < maxAttempts else { return }
		let delay = baseDelay * pow(2, Double(attempts))
		attempts += 1
		schedule(delay) { [weak self] in self?.reload() }
	}

	public func playbackDidRecover() {
		attempts = 0
	}

	nonisolated public static func liveSchedule(_ delay: TimeInterval, _ work: @escaping @MainActor () -> Void) {
		Task { @MainActor in
			try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
			work()
		}
	}
}
