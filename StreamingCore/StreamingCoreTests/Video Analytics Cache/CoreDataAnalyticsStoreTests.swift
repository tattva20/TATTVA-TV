//
//  CoreDataAnalyticsStoreTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
@testable import StreamingCore

@MainActor
final class CoreDataAnalyticsStoreTests: XCTestCase {

	func test_retrieve_deliversNilForUnknownSession() async throws {
		let sut = try makeSUT()

		let result = try await sut.retrieve(sessionID: UUID())

		XCTAssertNil(result)
	}

	func test_insertThenRetrieve_deliversTheSessionWithNoEvents() async throws {
		let sut = try makeSUT()
		let session = makeSession()

		try await sut.insert(session)
		let result = try await sut.retrieve(sessionID: session.id)

		XCTAssertEqual(result?.session, session)
		XCTAssertEqual(result?.events, [])
	}

	func test_insertEventThenRetrieve_deliversTheEvent() async throws {
		let sut = try makeSUT()
		let session = makeSession()
		try await sut.insert(session)
		let event = makeEvent(sessionID: session.id)

		try await sut.insertEvent(event)
		let result = try await sut.retrieve(sessionID: session.id)

		XCTAssertEqual(result?.events, [event])
	}

	func test_updateSession_persistsTheNewValues() async throws {
		let sut = try makeSUT()
		var session = makeSession()
		try await sut.insert(session)

		session.endTime = Date(timeIntervalSince1970: 999)
		try await sut.updateSession(session)
		let result = try await sut.retrieve(sessionID: session.id)

		XCTAssertEqual(result?.session.endTime, Date(timeIntervalSince1970: 999))
	}

	func test_deleteSession_removesItAndItsEvents() async throws {
		let sut = try makeSUT()
		let session = makeSession()
		try await sut.insert(session)
		try await sut.insertEvent(makeEvent(sessionID: session.id))

		try await sut.deleteSession(session.id)

		let result = try await sut.retrieve(sessionID: session.id)
		XCTAssertNil(result)
	}

	func test_deleteAllSessions_clearsTheStore() async throws {
		let sut = try makeSUT()
		try await sut.insert(makeSession())
		try await sut.insert(makeSession())

		try await sut.deleteAllSessions()

		let all = try await sut.retrieveAllSessions()
		XCTAssertEqual(all, [])
	}

	func test_insert_evictsTheOldestSessionsBeyondTheMaximum() async throws {
		let sut = try makeSUT(maxSessions: 2)
		let oldest = makeSession(startTime: Date(timeIntervalSince1970: 1))
		let middle = makeSession(startTime: Date(timeIntervalSince1970: 2))
		let newest = makeSession(startTime: Date(timeIntervalSince1970: 3))

		try await sut.insert(oldest)
		try await sut.insert(middle)
		try await sut.insert(newest)

		let remaining = Set(try await sut.retrieveAllSessions().map(\.id))
		XCTAssertEqual(remaining, [middle.id, newest.id], "Expected the oldest session to be evicted once the cap is exceeded")
		let evicted = try await sut.retrieve(sessionID: oldest.id)
		XCTAssertNil(evicted)
	}

	// MARK: - Helpers

	private func makeSUT(maxSessions: Int = 50, file: StaticString = #filePath, line: UInt = #line) throws -> CoreDataAnalyticsStore {
		let store = try CoreDataAnalyticsStore(storeURL: URL(fileURLWithPath: "/dev/null"), maxSessions: maxSessions)
		trackForMemoryLeaks(store, file: file, line: line)
		return store
	}

	private func makeSession(startTime: Date = Date(timeIntervalSince1970: 100)) -> LocalPlaybackSession {
		LocalPlaybackSession(
			id: UUID(),
			videoID: UUID(),
			videoTitle: "Any Video",
			startTime: startTime,
			endTime: nil,
			deviceModel: "Test Device",
			osVersion: "1.0",
			networkType: "wifi",
			appVersion: "1.0.0")
	}

	private func makeEvent(sessionID: UUID) -> LocalPlaybackEvent {
		LocalPlaybackEvent(
			id: UUID(),
			sessionID: sessionID,
			videoID: UUID(),
			eventType: "play",
			eventData: nil,
			timestamp: Date(timeIntervalSince1970: 200),
			currentPosition: 12)
	}
}
