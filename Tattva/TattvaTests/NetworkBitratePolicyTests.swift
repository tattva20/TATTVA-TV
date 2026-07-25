//
//  NetworkBitratePolicyTests.swift
//  TattvaTests
//
//  Copyright by Octavio Rojas all rights reserved.
//

import XCTest
import StreamingCore
@testable import StreamingCorePlayback

final class NetworkBitratePolicyTests: XCTestCase {
	func test_peakBitRate_capsLowerQualityAndUncapsExcellent() {
		let sut = NetworkBitratePolicy()

		XCTAssertEqual(sut.peakBitRate(for: .offline), 600_000)
		XCTAssertEqual(sut.peakBitRate(for: .poor), 600_000)
		XCTAssertEqual(sut.peakBitRate(for: .fair), 1_500_000)
		XCTAssertEqual(sut.peakBitRate(for: .good), 3_000_000)
		XCTAssertEqual(sut.peakBitRate(for: .excellent), 0, "0 means uncapped — ABR picks the maximum")
	}

	func test_peakBitRate_isMonotonicFromPoorToGood() {
		let sut = NetworkBitratePolicy()

		XCTAssertLessThanOrEqual(sut.peakBitRate(for: .poor), sut.peakBitRate(for: .fair))
		XCTAssertLessThanOrEqual(sut.peakBitRate(for: .fair), sut.peakBitRate(for: .good))
	}
}
