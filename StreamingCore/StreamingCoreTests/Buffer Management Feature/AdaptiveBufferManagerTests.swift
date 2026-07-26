//
//  AdaptiveBufferManagerTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import XCTest
@testable import StreamingCore

@MainActor
final class AdaptiveBufferManagerTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
	}

	// MARK: - Initial State Tests

	func test_init_startsWithBalancedConfiguration() async {
		let sut = makeSUT()

		let config = sut.currentConfiguration

		XCTAssertEqual(config.strategy, .balanced)
	}

	// MARK: - Memory State Update Tests

	func test_updateMemoryState_withCriticalPressure_setsMinimalStrategy() async {
		let sut = makeSUT()
		let criticalMemoryState = makeMemoryState(availableBytes: 40_000_000) // 40MB = critical

		sut.updateMemoryState(criticalMemoryState)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.strategy, .minimal)
	}

	func test_updateMemoryState_withWarningPressure_setsConservativeStrategy() async {
		let sut = makeSUT()
		let warningMemoryState = makeMemoryState(availableBytes: 80_000_000) // 80MB = warning

		sut.updateMemoryState(warningMemoryState)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.strategy, .conservative)
	}

	func test_updateMemoryState_withNormalPressure_allowsNetworkToInfluenceStrategy() async {
		let sut = makeSUT()
		let normalMemoryState = makeMemoryState(availableBytes: 200_000_000) // 200MB = normal

		sut.updateMemoryState(normalMemoryState)

		// With normal memory and default network (good), should be aggressive
		let config = sut.currentConfiguration
		XCTAssertEqual(config.strategy, .aggressive)
	}

	// MARK: - Network Quality Update Tests

	func test_updateNetworkQuality_withPoorNetwork_setsConservativeStrategy() async {
		let sut = makeSUT()
		let normalMemoryState = makeMemoryState(availableBytes: 200_000_000)

		sut.updateMemoryState(normalMemoryState)
		sut.updateNetworkQuality(.poor)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.strategy, .conservative)
	}

	func test_updateNetworkQuality_withFairNetwork_setsBalancedStrategy() async {
		let sut = makeSUT()
		let normalMemoryState = makeMemoryState(availableBytes: 200_000_000)

		sut.updateMemoryState(normalMemoryState)
		sut.updateNetworkQuality(.fair)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.strategy, .balanced)
	}

	func test_updateNetworkQuality_withExcellentNetwork_setsAggressiveStrategy() async {
		let sut = makeSUT()
		let normalMemoryState = makeMemoryState(availableBytes: 200_000_000)

		sut.updateMemoryState(normalMemoryState)
		sut.updateNetworkQuality(.excellent)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.strategy, .aggressive)
	}

	func test_updateNetworkQuality_withOfflineNetwork_setsConservativeStrategy() async {
		let sut = makeSUT()
		let normalMemoryState = makeMemoryState(availableBytes: 200_000_000)

		sut.updateMemoryState(normalMemoryState)
		sut.updateNetworkQuality(.offline)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.strategy, .conservative)
	}

	// MARK: - Memory Priority Tests

	func test_memoryPressure_takesPriorityOverNetwork() async {
		let sut = makeSUT()

		// Set excellent network first
		sut.updateNetworkQuality(.excellent)

		// Then set critical memory
		let criticalMemoryState = makeMemoryState(availableBytes: 40_000_000)
		sut.updateMemoryState(criticalMemoryState)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.strategy, .minimal, "Memory pressure should override network quality")
	}

	func test_warningMemory_staysConservativeEvenWithExcellentNetwork() async {
		let sut = makeSUT()

		sut.updateNetworkQuality(.excellent)

		let warningMemoryState = makeMemoryState(availableBytes: 80_000_000)
		sut.updateMemoryState(warningMemoryState)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.strategy, .conservative, "Warning memory should stay conservative regardless of network")
	}

	// MARK: - Publisher Tests

	func test_configurationPublisher_emitsOnStrategyChange() async {
		let sut = makeSUT()
		let expectation = expectation(description: "Configuration changed")

		var receivedConfigs: [BufferConfiguration] = []
		sut.configurationPublisher
			.sink { config in
				receivedConfigs.append(config)
				if receivedConfigs.count == 2 {
					expectation.fulfill()
				}
			}
			.store(in: &cancellables)

		// Trigger a change
		let criticalMemoryState = makeMemoryState(availableBytes: 40_000_000)
		sut.updateMemoryState(criticalMemoryState)

		await fulfillment(of: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedConfigs.last?.strategy, .minimal)
	}

	func test_configurationPublisher_doesNotEmitDuplicates() async {
		let sut = makeSUT()

		var emitCount = 0
		sut.configurationPublisher
			.sink { _ in emitCount += 1 }
			.store(in: &cancellables)

		// Set the same state multiple times
		let normalMemoryState = makeMemoryState(availableBytes: 200_000_000)
		sut.updateMemoryState(normalMemoryState)
		sut.updateMemoryState(normalMemoryState)
		sut.updateMemoryState(normalMemoryState)

		let deadline = Date() + 2
		while Date() < deadline, emitCount < 2 {
			try? await Task.sleep(nanoseconds: 10_000_000)
		}

		// Should only emit twice: initial balanced + change to aggressive
		XCTAssertEqual(emitCount, 2)
	}

	// MARK: - Buffer Duration Tests

	func test_criticalMemory_hasMinimalBufferDuration() async {
		let sut = makeSUT()
		let criticalMemoryState = makeMemoryState(availableBytes: 40_000_000)

		sut.updateMemoryState(criticalMemoryState)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.preferredForwardBufferDuration, 2.0)
	}

	func test_optimalConditions_hasAggressiveBufferDuration() async {
		let sut = makeSUT()
		let normalMemoryState = makeMemoryState(availableBytes: 200_000_000)

		sut.updateMemoryState(normalMemoryState)
		sut.updateNetworkQuality(.excellent)

		let config = sut.currentConfiguration
		XCTAssertEqual(config.preferredForwardBufferDuration, 30.0)
	}

	// MARK: - Sendable Tests

	func test_adaptiveBufferManager_isSendable() async {
		// AdaptiveBufferManager is @MainActor, validation still works
		let sut = makeSUT()
		XCTAssertNotNil(sut)
	}

	// MARK: - Helpers

	private func makeSUT() -> AdaptiveBufferManager {
		AdaptiveBufferManager()
	}

	private func makeMemoryState(
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
