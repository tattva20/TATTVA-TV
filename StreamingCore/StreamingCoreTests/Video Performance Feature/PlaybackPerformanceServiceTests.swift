//
//  PlaybackPerformanceServiceTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import Combine
@testable import StreamingCore

@MainActor
final class PlaybackPerformanceServiceTests: XCTestCase {

	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		cancellables.removeAll()
		super.tearDown()
	}

	// MARK: - Initialization Tests

	func test_init_doesNotEmitSnapshots() async {
		let sut = makeSUT()
		var receivedSnapshots: [PerformanceSnapshot] = []

		sut.metricsPublisher
			.sink { receivedSnapshots.append($0) }
			.store(in: &cancellables)

		// Give time for any emissions
		try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

		XCTAssertTrue(receivedSnapshots.isEmpty)
	}

	// MARK: - startMonitoring Tests

	func test_startMonitoring_setsSessionID() async {
		let sut = makeSUT()
		let sessionID = UUID()
		var receivedSnapshots: [PerformanceSnapshot] = []

		let expectation = self.expectation(description: "Wait for snapshot")
		let cancellable = sut.metricsPublisher
			.first()
			.sink {
				receivedSnapshots.append($0)
				expectation.fulfill()
			}

		sut.startMonitoring(for: sessionID)
		sut.recordEvent(.loadStarted)

		await fulfillment(of: [expectation], timeout: 1.0)
		cancellable.cancel()

		XCTAssertEqual(receivedSnapshots.first?.sessionID, sessionID)
	}

	// MARK: - recordEvent Tests

	func test_recordEvent_loadStarted_recordsInStartupTracker() async {
		let sut = makeSUT()
		let sessionID = UUID()
		var receivedSnapshots: [PerformanceSnapshot] = []

		let expectation = self.expectation(description: "Wait for snapshot")
		let cancellable = sut.metricsPublisher
			.first()
			.sink {
				receivedSnapshots.append($0)
				expectation.fulfill()
			}

		sut.startMonitoring(for: sessionID)
		sut.recordEvent(.loadStarted)

		await fulfillment(of: [expectation], timeout: 1.0)
		cancellable.cancel()

		XCTAssertNotNil(receivedSnapshots.first)
	}

	func test_recordEvent_firstFrameRendered_emitsSnapshotWithTimeToFirstFrame() async throws {
		let (sut, currentDate) = makeSUTWithDate()
		let sessionID = UUID()
		let startTime = Date()
		currentDate.value = startTime
		var receivedSnapshots: [PerformanceSnapshot] = []

		// Subscribe to capture snapshots after firstFrameRendered
		let expectation = self.expectation(description: "Wait for snapshot")
		let cancellable = sut.metricsPublisher
			.dropFirst() // Skip loadStarted snapshot, wait for firstFrameRendered
			.first()
			.sink {
				receivedSnapshots.append($0)
				expectation.fulfill()
			}

		sut.startMonitoring(for: sessionID)
		sut.recordEvent(.loadStarted)

		currentDate.value = startTime.addingTimeInterval(1.5)
		sut.recordEvent(.firstFrameRendered)

		await fulfillment(of: [expectation], timeout: 1.0)
		cancellable.cancel()

		let snapshot = try XCTUnwrap(receivedSnapshots.first)
		let timeToFirstFrame = try XCTUnwrap(snapshot.timeToFirstFrame)
		XCTAssertEqual(timeToFirstFrame, 1.5, accuracy: 0.001)
	}

	func test_recordEvent_bufferingStarted_setsIsBuffering() async {
		let sut = makeSUT()
		let sessionID = UUID()
		var receivedSnapshots: [PerformanceSnapshot] = []

		let expectation = self.expectation(description: "Wait for snapshot")
		let cancellable = sut.metricsPublisher
			.first()
			.sink {
				receivedSnapshots.append($0)
				expectation.fulfill()
			}

		sut.startMonitoring(for: sessionID)
		sut.recordEvent(.bufferingStarted)

		await fulfillment(of: [expectation], timeout: 1.0)
		cancellable.cancel()

		XCTAssertTrue(receivedSnapshots.first?.isBuffering ?? false)
	}

	func test_recordEvent_bufferingEnded_incrementsBufferingCount() async {
		let sut = makeSUT()
		let sessionID = UUID()
		var receivedSnapshots: [PerformanceSnapshot] = []

		let expectation = self.expectation(description: "Wait for snapshot")
		let cancellable = sut.metricsPublisher
			.dropFirst() // Skip bufferingStarted
			.first()
			.sink {
				receivedSnapshots.append($0)
				expectation.fulfill()
			}

		sut.startMonitoring(for: sessionID)
		sut.recordEvent(.bufferingStarted)
		sut.recordEvent(.bufferingEnded(duration: 2.0))

		await fulfillment(of: [expectation], timeout: 1.0)
		cancellable.cancel()

		XCTAssertFalse(receivedSnapshots.first?.isBuffering ?? true)
		XCTAssertEqual(receivedSnapshots.first?.bufferingCount, 1)
	}

	func test_recordEvent_networkChanged_updatesNetworkQuality() async {
		let sut = makeSUT()
		let sessionID = UUID()
		var receivedSnapshots: [PerformanceSnapshot] = []

		let expectation = self.expectation(description: "Wait for snapshot")
		let cancellable = sut.metricsPublisher
			.first()
			.sink {
				receivedSnapshots.append($0)
				expectation.fulfill()
			}

		sut.startMonitoring(for: sessionID)
		sut.recordEvent(.networkChanged(quality: .poor))

		await fulfillment(of: [expectation], timeout: 1.0)
		cancellable.cancel()

		XCTAssertEqual(receivedSnapshots.first?.networkQuality, .poor)
	}

	func test_recordEvent_qualityChanged_updatesBitrate() async {
		let sut = makeSUT()
		let sessionID = UUID()
		var receivedSnapshots: [PerformanceSnapshot] = []

		let expectation = self.expectation(description: "Wait for snapshot")
		let cancellable = sut.metricsPublisher
			.first()
			.sink {
				receivedSnapshots.append($0)
				expectation.fulfill()
			}

		sut.startMonitoring(for: sessionID)
		sut.recordEvent(.qualityChanged(bitrate: 6_000_000))

		await fulfillment(of: [expectation], timeout: 1.0)
		cancellable.cancel()

		XCTAssertEqual(receivedSnapshots.first?.currentBitrate, 6_000_000)
	}

	// MARK: - Alert Tests

	func test_slowStartup_emitsWarningAlert() async {
		let (_, currentDate) = makeSUTWithDate()
		let thresholds = PerformanceThresholds(
			acceptableStartupTime: 1.0,
			warningStartupTime: 2.0,
			criticalStartupTime: 4.0,
			acceptableRebufferingRatio: 0.01,
			warningRebufferingRatio: 0.03,
			criticalRebufferingRatio: 0.05,
			maxBufferingDuration: 10.0,
			maxBufferingEventsPerMinute: 3,
			warningMemoryMB: 150.0,
			criticalMemoryMB: 250.0
		)

		let sut2 = PlaybackPerformanceService(
			thresholds: thresholds,
			currentDate: { currentDate.value },
			uuidGenerator: { UUID() }
		)

		var receivedAlerts: [PerformanceAlert] = []
		sut2.alertPublisher
			.sink { receivedAlerts.append($0) }
			.store(in: &cancellables)

		let sessionID = UUID()
		let startTime = Date()
		currentDate.value = startTime

		sut2.startMonitoring(for: sessionID)
		sut2.recordEvent(.loadStarted)

		// Simulate 3 second startup (between warning and critical)
		currentDate.value = startTime.addingTimeInterval(3.0)
		sut2.recordEvent(.firstFrameRendered)

		// Give time for alert to be emitted
		let deadline = Date() + 2
		while Date() < deadline, receivedAlerts.isEmpty {
			try? await Task.sleep(nanoseconds: 10_000_000)
		}

		XCTAssertFalse(receivedAlerts.isEmpty)
		let alert = receivedAlerts.first
		if case .slowStartup = alert?.type {
			XCTAssertEqual(alert?.severity, .warning)
		} else {
			XCTFail("Expected slowStartup alert")
		}
	}

	func test_playbackStalled_emitsCriticalAlert() async {
		let sut = makeSUT()
		var receivedAlerts: [PerformanceAlert] = []

		sut.alertPublisher
			.sink { receivedAlerts.append($0) }
			.store(in: &cancellables)

		let sessionID = UUID()
		sut.startMonitoring(for: sessionID)
		sut.recordEvent(.playbackStalled)

		// Give time for alert to be emitted
		let deadline = Date() + 2
		while Date() < deadline, receivedAlerts.isEmpty {
			try? await Task.sleep(nanoseconds: 10_000_000)
		}

		XCTAssertFalse(receivedAlerts.isEmpty)
		let alert = receivedAlerts.first
		XCTAssertEqual(alert?.type, .playbackStalled)
		XCTAssertEqual(alert?.severity, .critical)
	}

	func test_memoryWarning_emitsAlert() async {
		let sut = makeSUT()
		var receivedAlerts: [PerformanceAlert] = []

		sut.alertPublisher
			.sink { receivedAlerts.append($0) }
			.store(in: &cancellables)

		let sessionID = UUID()
		sut.startMonitoring(for: sessionID)
		sut.recordEvent(.memoryWarning(level: .warning))

		// Give time for alert to be emitted
		let deadline = Date() + 2
		while Date() < deadline, receivedAlerts.isEmpty {
			try? await Task.sleep(nanoseconds: 10_000_000)
		}

		XCTAssertFalse(receivedAlerts.isEmpty)
		if case .memoryPressure(let level) = receivedAlerts.first?.type {
			XCTAssertEqual(level, .warning)
		} else {
			XCTFail("Expected memoryPressure alert")
		}
	}

	// MARK: - stopMonitoring Tests

	func test_stopMonitoring_clearsSessionID() async {
		let sut = makeSUT()
		let sessionID = UUID()

		sut.startMonitoring(for: sessionID)
		sut.stopMonitoring()

		// After stopping, recording events should not produce snapshots
		sut.recordEvent(.loadStarted)

		var receivedSnapshots: [PerformanceSnapshot] = []
		sut.metricsPublisher
			.sink { receivedSnapshots.append($0) }
			.store(in: &cancellables)

		try? await Task.sleep(nanoseconds: 100_000_000)
		XCTAssertTrue(receivedSnapshots.isEmpty)
	}

	// MARK: - Helpers

	private func makeSUT(
		thresholds: PerformanceThresholds = .default,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> PlaybackPerformanceService {
		let sut = PlaybackPerformanceService(thresholds: thresholds)
		return sut
	}

	private func makeSUTWithDate(
		thresholds: PerformanceThresholds = .default,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: PlaybackPerformanceService, currentDate: CurrentDateStub) {
		let currentDate = CurrentDateStub()
		let sut = PlaybackPerformanceService(
			thresholds: thresholds,
			currentDate: { currentDate.value },
			uuidGenerator: { UUID() }
		)
		return (sut, currentDate)
	}

	private func waitForSnapshot(from sut: PlaybackPerformanceService, timeout: TimeInterval = 0.5) async -> PerformanceSnapshot? {
		var snapshot: PerformanceSnapshot?

		let expectation = self.expectation(description: "Wait for snapshot")

		let cancellable = sut.metricsPublisher
			.first()
			.sink { received in
				snapshot = received
				expectation.fulfill()
			}

		await fulfillment(of: [expectation], timeout: timeout)
		cancellable.cancel()

		return snapshot
	}
}

// MARK: - Test Helpers

@MainActor
private final class CurrentDateStub {
	var value: Date = Date()
}
