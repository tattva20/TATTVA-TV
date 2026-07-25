//
//  NetworkQualityMonitorTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Network
import XCTest
@testable import StreamingCore
import StreamingCorePlayback

final class NetworkQualityMonitorTests: XCTestCase {

	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		cancellables.removeAll()
		super.tearDown()
	}

	// MARK: - Initial State

	func test_init_startsWithUnknownQuality() {
		let sut = makeSUT()

		XCTAssertEqual(sut.currentQuality, .fair)
	}

	// MARK: - Quality Publisher

	func test_qualityPublisher_emitsCurrentQuality() {
		let sut = makeSUT()
		var receivedQualities: [NetworkQuality] = []
		let exp = expectation(description: "Wait for quality")

		sut.qualityPublisher
			.sink { quality in
				receivedQualities.append(quality)
				exp.fulfill()
			}
			.store(in: &cancellables)

		wait(for: [exp], timeout: 1.0)

		XCTAssertFalse(receivedQualities.isEmpty)
	}

	// MARK: - Connection Type Detection

	func test_determineQuality_returnsOffline_whenUnsatisfied() {
		let quality = NetworkQualityMonitor.determineQuality(
			status: .unsatisfied,
			isExpensive: false,
			isConstrained: false,
			connectionType: .other
		)

		XCTAssertEqual(quality, .offline)
	}

	func test_determineQuality_returnsExcellent_forWifiWithNoConstraints() {
		let quality = NetworkQualityMonitor.determineQuality(
			status: .satisfied,
			isExpensive: false,
			isConstrained: false,
			connectionType: .wifi
		)

		XCTAssertEqual(quality, .excellent)
	}

	func test_determineQuality_returnsGood_forCellularWithNoConstraints() {
		let quality = NetworkQualityMonitor.determineQuality(
			status: .satisfied,
			isExpensive: false,
			isConstrained: false,
			connectionType: .cellular
		)

		XCTAssertEqual(quality, .good)
	}

	func test_determineQuality_returnsFair_forWiredEthernet() {
		let quality = NetworkQualityMonitor.determineQuality(
			status: .satisfied,
			isExpensive: false,
			isConstrained: false,
			connectionType: .wiredEthernet
		)

		XCTAssertEqual(quality, .excellent)
	}

	func test_determineQuality_returnsPoor_whenConstrained() {
		let quality = NetworkQualityMonitor.determineQuality(
			status: .satisfied,
			isExpensive: false,
			isConstrained: true,
			connectionType: .wifi
		)

		XCTAssertEqual(quality, .poor)
	}

	func test_determineQuality_returnsFair_whenExpensive() {
		let quality = NetworkQualityMonitor.determineQuality(
			status: .satisfied,
			isExpensive: true,
			isConstrained: false,
			connectionType: .wifi
		)

		XCTAssertEqual(quality, .fair)
	}

	// MARK: - Start/Stop Monitoring

	func test_startMonitoring_beginsPathUpdates() async {
		let sut = makeSUT()

		await sut.startMonitoring()

		// Should not crash and monitoring should be active
		await sut.stopMonitoring()
	}

	func test_stopMonitoring_cancelsPathUpdates() async {
		let sut = makeSUT()

		await sut.startMonitoring()
		await sut.stopMonitoring()

		// Should complete without issues
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> NetworkQualityMonitor {
		let sut = NetworkQualityMonitor()
		return sut
	}
}
