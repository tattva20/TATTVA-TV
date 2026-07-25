//
//  VideoPlayerPerformanceAdapter.swift
//  StreamingCorePlayback
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import StreamingCore

/// Bridges AVPlayer performance observations to the platform-agnostic PerformanceMonitor
/// Coordinates bandwidth estimation with network quality monitoring
/// Uses @MainActor isolation following Essential Feed patterns for thread-safety.
@MainActor
public final class VideoPlayerPerformanceAdapter {

	private let performanceService: any PerformanceMonitor
	private let bandwidthEstimator: NetworkBandwidthEstimator
	private var cancellables = Set<AnyCancellable>()

	private var _isObserving = false
	private var hasRecordedFirstFrame = false

	public var isObserving: Bool { _isObserving }

	public init(
		performanceService: any PerformanceMonitor,
		bandwidthEstimator: NetworkBandwidthEstimator
	) {
		self.performanceService = performanceService
		self.bandwidthEstimator = bandwidthEstimator
	}

	// MARK: - Monitoring Control

	public func startMonitoring(sessionID: UUID) {
		performanceService.startMonitoring(for: sessionID)
		_isObserving = true
		hasRecordedFirstFrame = false
	}

	public func stopMonitoring() {
		_isObserving = false
		performanceService.stopMonitoring()
		cancellables.removeAll()
	}

	// MARK: - Quality Updates

	public func updateNetworkQuality(_ quality: NetworkQuality) {
		performanceService.recordEvent(.networkChanged(quality: quality))
		if let service = performanceService as? PlaybackPerformanceService {
			service.updateNetwork(quality)
		}
	}

	public func updateMemory(usedMB: Double, pressure: MemoryPressureLevel) {
		performanceService.recordEvent(.memoryWarning(level: pressure))
		if let service = performanceService as? PlaybackPerformanceService {
			service.updateMemory(usedMB: usedMB, pressure: pressure)
		}
	}

	// MARK: - Bandwidth Tracking

	public func recordBandwidthSample(bytesTransferred: Int64, duration: TimeInterval) {
		let sample = BandwidthSample(
			bytesTransferred: bytesTransferred,
			duration: duration,
			timestamp: Date()
		)
		bandwidthEstimator.recordSample(sample)
		performanceService.recordEvent(.bytesTransferred(bytes: bytesTransferred, duration: duration))
	}

	public var currentBandwidthEstimate: BandwidthEstimate {
		bandwidthEstimator.currentEstimate
	}

	// MARK: - AVPlayer Observer Integration

	public func observePlayer(_ observer: AVPlayerPerformanceObserver) {
		observer.playbackStatePublisher
			.removeDuplicates()
			.sink { [weak self] state in
				self?.handlePlaybackStateChange(state)
			}
			.store(in: &cancellables)

		observer.bufferingStatePublisher
			.removeDuplicates()
			.sink { [weak self] state in
				self?.handleBufferingStateChange(state)
			}
			.store(in: &cancellables)

		// AVPlayerPerformanceObserver emits StreamingCore.PerformanceEvent directly
		observer.performanceEventPublisher
			.sink { [weak self] event in
				self?.handlePerformanceEvent(event)
			}
			.store(in: &cancellables)
	}

	// MARK: - Private Handlers

	private func handlePlaybackStateChange(_ state: ObserverPlaybackState) {
		guard _isObserving else { return }

		switch state {
		case .playing:
			if !hasRecordedFirstFrame {
				hasRecordedFirstFrame = true
				performanceService.recordEvent(.firstFrameRendered)
			}
			performanceService.recordEvent(.playbackResumed)

		case .buffering:
			performanceService.recordEvent(.bufferingStarted)

		case .stalled:
			performanceService.recordEvent(.playbackStalled)

		case .paused, .idle:
			break

		case .failed:
			performanceService.recordEvent(.playbackStalled)

		@unknown default:
			break
		}
	}

	private func handleBufferingStateChange(_ state: BufferingState) {
		guard _isObserving else { return }

		switch state {
		case .buffering:
			performanceService.recordEvent(.bufferingStarted)

		case .ready:
			performanceService.recordEvent(.bufferingEnded(duration: 0))

		case .stalled:
			performanceService.recordEvent(.playbackStalled)

		case .unknown:
			break

		@unknown default:
			break
		}
	}

	private func handlePerformanceEvent(_ event: StreamingCore.PerformanceEvent) {
		guard _isObserving else { return }

		// Handle bandwidth tracking specially for the estimator
		if case .bytesTransferred(let bytes, let duration) = event {
			let sample = BandwidthSample(
				bytesTransferred: bytes,
				duration: duration,
				timestamp: Date()
			)
			bandwidthEstimator.recordSample(sample)
		}
		// Forward all events to the performance service
		performanceService.recordEvent(event)
	}
}
