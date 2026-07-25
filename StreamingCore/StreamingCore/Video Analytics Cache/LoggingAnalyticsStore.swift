//
//  LoggingAnalyticsStore.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//

import Foundation

public final class LoggingAnalyticsStore: AnalyticsStore {
	private let decoratee: AnalyticsStore
	private let logger: any Logger

	public init(decoratee: AnalyticsStore, logger: any Logger) {
		self.decoratee = decoratee
		self.logger = logger
	}

	public func insert(_ session: LocalPlaybackSession) async throws {
		logQoE("session.start", metadata: [
			"sessionID": session.id.uuidString,
			"videoTitle": session.videoTitle,
			"network": session.networkType ?? "unknown",
			"osVersion": session.osVersion,
			"appVersion": session.appVersion
		])
		try await decoratee.insert(session)
	}

	public func insertEvent(_ event: LocalPlaybackEvent) async throws {
		logQoE("event", metadata: [
			"type": event.eventType,
			"sessionID": event.sessionID.uuidString,
			"position": String(format: "%.2f", event.currentPosition)
		])
		try await decoratee.insertEvent(event)
	}

	public func updateSession(_ session: LocalPlaybackSession) async throws {
		var metadata = ["sessionID": session.id.uuidString]
		if let endTime = session.endTime {
			metadata["durationSeconds"] = String(format: "%.2f", endTime.timeIntervalSince(session.startTime))
		}
		logQoE("session.end", metadata: metadata)
		try await decoratee.updateSession(session)
	}

	public func retrieve(sessionID: UUID) async throws -> (session: LocalPlaybackSession, events: [LocalPlaybackEvent])? {
		try await decoratee.retrieve(sessionID: sessionID)
	}

	public func retrieveAllSessions() async throws -> [LocalPlaybackSession] {
		try await decoratee.retrieveAllSessions()
	}

	public func deleteSession(_ sessionID: UUID) async throws {
		try await decoratee.deleteSession(sessionID)
	}

	public func deleteAllSessions() async throws {
		try await decoratee.deleteAllSessions()
	}

	private func logQoE(_ message: String, metadata: [String: String]) {
		let context = LogContext(subsystem: "Analytics", category: "QoE", metadata: metadata)
		logger.log(LogEntry(level: .info, message: message, context: context))
	}
}
