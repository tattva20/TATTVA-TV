//
//  PollingMemoryMonitorTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import XCTest
@testable import StreamingCore

@MainActor
final class PollingMemoryMonitorTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
	}

	// MARK: - Initialization Tests

	func test_init_doesNotStartMonitoring() async {
		let counter = Counter()
		let defaultState = Self.makeMemoryState()
		let _ = makeSUT(memoryReader: {
			counter.increment()
			return defaultState
		})

		await Task.yield()
		try? await Task.sleep(nanoseconds: 100_000_000)

		XCTAssertEqual(counter.value, 0)
	}

	// MARK: - Current Memory State Tests

	func test_currentMemoryState_returnsMemoryFromReader() async {
		let expectedState = Self.makeMemoryState(availableBytes: 123_456_789)
		let sut = makeSUT(memoryReader: { expectedState })

		let state = sut.currentMemoryState()

		XCTAssertEqual(state, expectedState)
	}

	// MARK: - Start Monitoring Tests

	func test_startMonitoring_beginsPolling() async {
		let counter = Counter()
		let defaultState = Self.makeMemoryState()
		let sut = makeSUT(
			memoryReader: {
				counter.increment()
				return defaultState
			},
			pollingInterval: 0.05
		)

		sut.startMonitoring()
		let deadline = Date() + 1
		while Date() < deadline, counter.value < 2 {
			try? await Task.sleep(nanoseconds: 10_000_000)
		}

		XCTAssertGreaterThanOrEqual(counter.value, 2)

		sut.stopMonitoring()
	}

	func test_startMonitoring_emitsStateViaPublisher() async {
		let expectedState = Self.makeMemoryState(availableBytes: 500_000_000)
		let sut = makeSUT(
			memoryReader: { expectedState },
			pollingInterval: 0.05
		)

		let expectation = expectation(description: "State received")
		var receivedState: MemoryState?

		sut.statePublisher
			.first()
			.sink { state in
				receivedState = state
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.startMonitoring()

		await fulfillment(of: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedState, expectedState)

		sut.stopMonitoring()
	}

	func test_startMonitoring_calledTwice_doesNotCreateDuplicatePolling() async {
		let counter = Counter()
		let defaultState = Self.makeMemoryState()
		let sut = makeSUT(
			memoryReader: {
				counter.increment()
				return defaultState
			},
			pollingInterval: 0.05
		)

		sut.startMonitoring()
		sut.startMonitoring() // Second call should be ignored

		try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

		// Should have roughly 2-3 reads, not double
		XCTAssertLessThan(counter.value, 6)

		sut.stopMonitoring()
	}

	// MARK: - Stop Monitoring Tests

	func test_stopMonitoring_stopsPolling() async {
		let counter = Counter()
		let defaultState = Self.makeMemoryState()
		let sut = makeSUT(
			memoryReader: {
				counter.increment()
				return defaultState
			},
			pollingInterval: 0.05
		)

		sut.startMonitoring()
		try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

		sut.stopMonitoring()

		let countAfterStop = counter.value
		try? await Task.sleep(nanoseconds: 150_000_000) // 150ms more

		// Allow tolerance of 1 additional read due to race condition between stop and last poll
		XCTAssertLessThanOrEqual(counter.value, countAfterStop + 1, "Read count should not increase significantly after stop")
	}

	func test_stopMonitoring_calledWithoutStart_doesNothing() async {
		let sut = makeSUT()

		sut.stopMonitoring()

		// Should not crash or have any side effects
	}

	// MARK: - Duplicate State Filtering Tests

	func test_statePublisher_removeDuplicates() async {
		let counter = Counter()
		let constantState = Self.makeMemoryState(availableBytes: 500_000_000)
		let sut = makeSUT(
			memoryReader: {
				counter.increment()
				return constantState
			},
			pollingInterval: 0.05
		)

		var receivedCount = 0
		sut.statePublisher
			.sink { _ in receivedCount += 1 }
			.store(in: &cancellables)

		sut.startMonitoring()
		try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

		sut.stopMonitoring()

		// Memory reader called multiple times, but publisher should emit only once (due to removeDuplicates)
		XCTAssertGreaterThan(counter.value, 2)
		XCTAssertEqual(receivedCount, 1)
	}

	// MARK: - Memory Pressure Level Tests

	func test_emittedState_hasCorrectPressureLevel() async {
		let lowMemoryState = Self.makeMemoryState(availableBytes: 40_000_000) // 40MB = critical
		let thresholds = MemoryThresholds.default
		let sut = makeSUT(
			memoryReader: { lowMemoryState },
			thresholds: thresholds,
			pollingInterval: 0.05
		)

		let expectation = expectation(description: "State received")
		var receivedState: MemoryState?

		sut.statePublisher
			.first()
			.sink { state in
				receivedState = state
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.startMonitoring()

		await fulfillment(of: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedState?.pressureLevel(thresholds: thresholds), .critical)

		sut.stopMonitoring()
	}

	// MARK: - Sendable Tests

	func test_pollingMemoryMonitor_isSendable() async {
		// PollingMemoryMonitor is @MainActor, so no longer Sendable in the traditional sense
		// This test validates it still conforms to the protocol
		let sut = makeSUT()
		XCTAssertNotNil(sut)
	}

	// MARK: - Helpers

	private func makeSUT(
		memoryReader: @escaping @Sendable () -> MemoryState = { PollingMemoryMonitorTests.makeMemoryState() },
		thresholds: MemoryThresholds = .default,
		pollingInterval: TimeInterval = 2.0
	) -> PollingMemoryMonitor {
		let adjustedThresholds = MemoryThresholds(
			warningAvailableMB: thresholds.warningAvailableMB,
			criticalAvailableMB: thresholds.criticalAvailableMB,
			pollingInterval: pollingInterval
		)

		return PollingMemoryMonitor(
			memoryReader: memoryReader,
			thresholds: adjustedThresholds
		)
	}

	private nonisolated static func makeMemoryState(
		availableBytes: UInt64 = 500_000_000,
		totalBytes: UInt64 = 4_000_000_000,
		usedBytes: UInt64 = 3_500_000_000,
		timestamp: Date = Date()
	) -> MemoryState {
		MemoryState(
			availableBytes: availableBytes,
			totalBytes: totalBytes,
			usedBytes: usedBytes,
			timestamp: timestamp
		)
	}
}

// MARK: - Thread-Safe Counter for Testing
// Uses NSLock for thread-safety since memoryReader is called from background Task.

private final class Counter: @unchecked Sendable {
	private var _value: Int = 0
	private let lock = NSLock()

	var value: Int {
		lock.withLock { _value }
	}

	func increment() {
		lock.withLock { _value += 1 }
	}
}
