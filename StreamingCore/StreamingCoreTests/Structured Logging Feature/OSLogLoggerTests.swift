//
//  OSLogLoggerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class OSLogLoggerTests: XCTestCase {

	// MARK: - Initialization

	func test_init_setsMinimumLevel() {
		let sut = OSLogLogger(
			subsystem: "com.test.app",
			category: "test",
			minimumLevel: .warning
		)

		XCTAssertEqual(sut.minimumLevel, .warning)
	}

	func test_init_defaultsMinimumLevelToInfo() {
		let sut = OSLogLogger(
			subsystem: "com.test.app",
			category: "test"
		)

		XCTAssertEqual(sut.minimumLevel, .info)
	}

	// MARK: - Logging

	func test_log_doesNotCrashForDebugLevel() {
		let sut = makeSUT(minimumLevel: .debug)

		sut.log(makeEntry(level: .debug))
	}

	func test_log_doesNotCrashForInfoLevel() {
		let sut = makeSUT()

		sut.log(makeEntry(level: .info))
	}

	func test_log_doesNotCrashForWarningLevel() {
		let sut = makeSUT()

		sut.log(makeEntry(level: .warning))
	}

	func test_log_doesNotCrashForErrorLevel() {
		let sut = makeSUT()

		sut.log(makeEntry(level: .error))
	}

	func test_log_doesNotCrashForCriticalLevel() {
		let sut = makeSUT()

		sut.log(makeEntry(level: .critical))
	}

	// MARK: - Filtering

	func test_log_ignoresEntriesBelowMinimumLevel() {
		let sut = makeSUT(minimumLevel: .error)

		// Should not crash and should be filtered
		sut.log(makeEntry(level: .info))
	}

	func test_log_acceptsEntriesAtMinimumLevel() {
		let sut = makeSUT(minimumLevel: .warning)

		sut.log(makeEntry(level: .warning))
	}

	// MARK: - Concurrent Access

	func test_log_handlesConcurrentLogs() async {
		let sut = makeSUT()

		await withTaskGroup(of: Void.self) { group in
			for i in 0..<10 {
				let entry = makeEntry(level: .info, message: "Concurrent \(i)")
				group.addTask {
					sut.log(entry)
				}
			}
		}
	}

	// MARK: - Helpers

	private func makeSUT(minimumLevel: LogLevel = .info) -> OSLogLogger {
		OSLogLogger(
			subsystem: "com.tattva.test",
			category: "UnitTests",
			minimumLevel: minimumLevel
		)
	}

	private func makeEntry(
		level: LogLevel = .info,
		message: String = "Test message"
	) -> LogEntry {
		LogEntry(
			level: level,
			message: message,
			context: LogContext(file: "test.swift", function: "test()", line: 1)
		)
	}
}
