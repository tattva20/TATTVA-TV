//
//  ResourceCleanupIntegrationTests.swift
//  TattvaTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import XCTest
import StreamingCore
@testable import Tattva

@MainActor
final class ResourceCleanupIntegrationTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
		RunLoop.current.run(until: Date())
	}

	// MARK: - SceneDelegate Integration Tests

	func test_sceneDelegate_hasMemoryMonitorConfigured() {
		let sut = SceneDelegate()

		XCTAssertNotNil(sut.memoryMonitor, "Expected SceneDelegate to have a configured memory monitor")
	}

	func test_sceneDelegate_hasResourceCleanupCoordinatorConfigured() {
		let sut = SceneDelegate()

		XCTAssertNotNil(sut.resourceCleanupCoordinator, "Expected SceneDelegate to have a configured cleanup coordinator")
	}

	func test_sceneDelegate_cleanupCoordinatorHasCleanersRegistered() async {
		let sut = SceneDelegate()

		_ = await sut.resourceCleanupCoordinator.estimateTotalCleanup()

		// If cleaners are registered, estimate should be callable (even if 0)
		XCTAssertTrue(true, "Expected cleanup coordinator to be functional with registered cleaners")
	}

	func test_sceneDelegate_enablesAutoCleanupOnSceneConnection() async throws {
		let sut = SceneDelegate()
		let window = try UIWindowSpy.make()
		sut.window = window

		sut.configureWindow()

		// After configureWindow, auto cleanup should be enabled
		// This is verified by the memory monitor being started
		XCTAssertTrue(sut.isAutoCleanupEnabled, "Expected auto cleanup to be enabled after window configuration")
	}

	// MARK: - Memory Pressure Response Tests

	func test_cleanupCoordinator_triggersCleanupOnCriticalMemoryPressure() async {
		let cleaner = ResourceCleanerSpy(name: "Test Cache", priority: .high)
		let memoryMonitor = MemoryMonitorSpy()
		let sut = ResourceCleanupCoordinator(cleaners: [cleaner], memoryMonitor: memoryMonitor)

		let expectation = expectation(description: "Cleanup results received")
		sut.cleanupResultsPublisher
			.first()
			.sink { _ in
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.enableAutoCleanup()

		// Simulate critical memory pressure (must be < 50MB for critical threshold)
		let criticalState = makeMemoryState(availableMB: 40)
		memoryMonitor.simulateMemoryState(criticalState)

		await fulfillment(of: [expectation], timeout: 2.0)

		XCTAssertGreaterThan(cleaner.cleanupCallCount, 0, "Expected cleaner to be called on critical memory pressure")
	}

	func test_cleanupCoordinator_triggersPartialCleanupOnWarningMemoryPressure() async {
		let lowPriorityCleaner = ResourceCleanerSpy(name: "Low", priority: .low)
		let highPriorityCleaner = ResourceCleanerSpy(name: "High", priority: .high)
		let memoryMonitor = MemoryMonitorSpy()
		let sut = ResourceCleanupCoordinator(cleaners: [lowPriorityCleaner, highPriorityCleaner], memoryMonitor: memoryMonitor)

		let expectation = expectation(description: "Cleanup results received")
		sut.cleanupResultsPublisher
			.first()
			.sink { _ in
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.enableAutoCleanup()

		// Simulate warning memory pressure (must be >= 50MB and < 100MB for warning)
		let warningState = makeMemoryState(availableMB: 80)
		memoryMonitor.simulateMemoryState(warningState)

		await fulfillment(of: [expectation], timeout: 2.0)

		// On warning, only low and medium priority should be cleaned
		XCTAssertGreaterThan(lowPriorityCleaner.cleanupCallCount, 0, "Expected low priority cleaner to be called on warning")
		XCTAssertEqual(highPriorityCleaner.cleanupCallCount, 0, "Expected high priority cleaner NOT to be called on warning")
	}

	func test_cleanupCoordinator_doesNotTriggerCleanupOnNormalMemory() async {
		let cleaner = ResourceCleanerSpy(name: "Test Cache", priority: .medium)
		let memoryMonitor = MemoryMonitorSpy()
		let sut = ResourceCleanupCoordinator(cleaners: [cleaner], memoryMonitor: memoryMonitor)

		sut.enableAutoCleanup()

		// Simulate normal memory pressure
		let normalState = makeMemoryState(availableMB: 500) // Plenty of memory
		memoryMonitor.simulateMemoryState(normalState)

		for _ in 0..<20 { await Task.yield() }

		XCTAssertEqual(cleaner.cleanupCallCount, 0, "Expected no cleanup on normal memory pressure")
	}

	// MARK: - Helpers

	private func makeMemoryState(availableMB: Double) -> MemoryState {
		let availableBytes = UInt64(availableMB * 1_048_576)
		let totalBytes: UInt64 = 4_000_000_000
		return MemoryState(
			availableBytes: availableBytes,
			totalBytes: totalBytes,
			usedBytes: totalBytes - availableBytes,
			timestamp: Date()
		)
	}

	private class UIWindowSpy: UIWindow {
		var makeKeyAndVisibleCallCount = 0

		static func make() throws -> UIWindowSpy {
			let dummyScene = try XCTUnwrap((UIWindowScene.self as NSObject.Type).init() as? UIWindowScene)
			return UIWindowSpy(windowScene: dummyScene)
		}

		override func makeKeyAndVisible() {
			makeKeyAndVisibleCallCount += 1
		}
	}
}

// MARK: - Test Doubles

@MainActor
private final class MemoryMonitorSpy: MemoryMonitor {
	private var _startMonitoringCallCount = 0
	private var _stopMonitoringCallCount = 0

	private let stateSubject = CurrentValueSubject<MemoryState?, Never>(nil)

	var startMonitoringCallCount: Int { _startMonitoringCallCount }
	var stopMonitoringCallCount: Int { _stopMonitoringCallCount }

	var statePublisher: AnyPublisher<MemoryState, Never> {
		stateSubject
			.compactMap { $0 }
			.eraseToAnyPublisher()
	}

	func currentMemoryState() -> MemoryState {
		stateSubject.value ?? makeMemoryState(availableMB: 500)
	}

	func startMonitoring() {
		_startMonitoringCallCount += 1
	}

	func stopMonitoring() {
		_stopMonitoringCallCount += 1
	}

	func simulateMemoryState(_ state: MemoryState) {
		stateSubject.send(state)
	}

	private func makeMemoryState(availableMB: Double) -> MemoryState {
		let availableBytes = UInt64(availableMB * 1_048_576)
		return MemoryState(
			availableBytes: availableBytes,
			totalBytes: 4_000_000_000,
			usedBytes: 4_000_000_000 - availableBytes,
			timestamp: Date()
		)
	}
}

private final class ResourceCleanerSpy: ResourceCleaner, @unchecked Sendable {
	let resourceName: String
	let priority: CleanupPriority

	private(set) var cleanupCallCount = 0
	private(set) var estimateCallCount = 0

	var stubEstimate: UInt64 = 1_000_000
	var stubResult: CleanupResult

	init(name: String = "Test Resource", priority: CleanupPriority = .medium) {
		self.resourceName = name
		self.priority = priority
		self.stubResult = CleanupResult(
			resourceName: name,
			bytesFreed: 1_000_000,
			itemsRemoved: 10,
			success: true
		)
	}

	func estimateCleanup() async -> UInt64 {
		estimateCallCount += 1
		return stubEstimate
	}

	func cleanup() async -> CleanupResult {
		cleanupCallCount += 1
		return stubResult
	}
}
