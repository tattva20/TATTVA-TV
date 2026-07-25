//
//  LoggingAnalyticsStoreTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//

import XCTest
import StreamingCore

@MainActor
final class LoggingAnalyticsStoreTests: XCTestCase {

	func test_insert_logsSessionStartAndDelegates() async throws {
		let (sut, store, logger) = makeSUT()
		let session = makeSession()

		try await sut.insert(session)

		XCTAssertEqual(logger.messages, ["session.start"])
		XCTAssertEqual(store.insertedSessions, [session])
	}

	func test_insertEvent_logsEventAndDelegates() async throws {
		let (sut, store, logger) = makeSUT()
		let event = makeEvent()

		try await sut.insertEvent(event)

		XCTAssertEqual(logger.messages, ["event"])
		XCTAssertEqual(store.insertedEvents, [event])
	}

	func test_updateSession_logsSessionEndAndDelegates() async throws {
		let (sut, store, logger) = makeSUT()
		let session = makeSession()

		try await sut.updateSession(session)

		XCTAssertEqual(logger.messages, ["session.end"])
		XCTAssertEqual(store.updatedSessions, [session])
	}

	func test_retrieve_delegatesWithoutLogging() async throws {
		let (sut, store, logger) = makeSUT()

		_ = try await sut.retrieve(sessionID: UUID())

		XCTAssertTrue(logger.messages.isEmpty, "Reads should not emit QoE logs")
		XCTAssertEqual(store.retrieveCallCount, 1)
	}

	// MARK: - Helpers

	private func makeSUT() -> (sut: LoggingAnalyticsStore, store: AnalyticsStoreSpy, logger: LoggerSpy) {
		let store = AnalyticsStoreSpy()
		let logger = LoggerSpy()
		let sut = LoggingAnalyticsStore(decoratee: store, logger: logger)
		return (sut, store, logger)
	}

	private func makeSession() -> LocalPlaybackSession {
		LocalPlaybackSession(
			id: UUID(), videoID: UUID(), videoTitle: "Any", startTime: Date(),
			endTime: nil, deviceModel: "Sim", osVersion: "26.0", networkType: "wifi", appVersion: "1.0.0")
	}

	private func makeEvent() -> LocalPlaybackEvent {
		LocalPlaybackEvent(
			id: UUID(), sessionID: UUID(), videoID: UUID(), eventType: "play",
			eventData: nil, timestamp: Date(), currentPosition: 0)
	}

	@MainActor
	private final class AnalyticsStoreSpy: AnalyticsStore {
		private(set) var insertedSessions: [LocalPlaybackSession] = []
		private(set) var insertedEvents: [LocalPlaybackEvent] = []
		private(set) var updatedSessions: [LocalPlaybackSession] = []
		private(set) var retrieveCallCount = 0

		func insert(_ session: LocalPlaybackSession) async throws { insertedSessions.append(session) }
		func insertEvent(_ event: LocalPlaybackEvent) async throws { insertedEvents.append(event) }
		func updateSession(_ session: LocalPlaybackSession) async throws { updatedSessions.append(session) }
		func retrieve(sessionID: UUID) async throws -> (session: LocalPlaybackSession, events: [LocalPlaybackEvent])? {
			retrieveCallCount += 1
			return nil
		}
		func retrieveAllSessions() async throws -> [LocalPlaybackSession] { [] }
		func deleteSession(_ sessionID: UUID) async throws {}
		func deleteAllSessions() async throws {}
	}

	private final class LoggerSpy: Logger, @unchecked Sendable {
		let minimumLevel: LogLevel = .debug
		private let lock = NSLock()
		private var _messages: [String] = []
		var messages: [String] {
			lock.lock(); defer { lock.unlock() }
			return _messages
		}
		func log(_ entry: LogEntry) {
			lock.lock(); defer { lock.unlock() }
			_messages.append(entry.message)
		}
	}
}
