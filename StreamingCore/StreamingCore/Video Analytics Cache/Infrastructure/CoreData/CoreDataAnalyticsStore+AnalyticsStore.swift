//
//  CoreDataAnalyticsStore+AnalyticsStore.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import CoreData

extension CoreDataAnalyticsStore: AnalyticsStore {

	public func insert(_ session: LocalPlaybackSession) async throws {
		let context = self.context
		let maxSessions = self.maxSessions
		try await context.perform {
			let managed = try ManagedAnalyticsSession.first(with: session.id, in: context) ?? ManagedAnalyticsSession(context: context)
			managed.update(from: session)
			Self.enforceRetention(maxSessions: maxSessions, in: context)
			try context.save()
		}
	}

	public func insertEvent(_ event: LocalPlaybackEvent) async throws {
		let context = self.context
		try await context.perform {
			let managedEvent = ManagedAnalyticsEvent(context: context)
			managedEvent.update(from: event)
			managedEvent.session = try ManagedAnalyticsSession.first(with: event.sessionID, in: context)
			try context.save()
		}
	}

	public func updateSession(_ session: LocalPlaybackSession) async throws {
		let context = self.context
		try await context.perform {
			let managed = try ManagedAnalyticsSession.first(with: session.id, in: context) ?? ManagedAnalyticsSession(context: context)
			managed.update(from: session)
			try context.save()
		}
	}

	public func retrieve(sessionID: UUID) async throws -> (session: LocalPlaybackSession, events: [LocalPlaybackEvent])? {
		let context = self.context
		return try await context.perform {
			guard let managed = try ManagedAnalyticsSession.first(with: sessionID, in: context) else { return nil }
			return (managed.local, managed.localEvents)
		}
	}

	public func retrieveAllSessions() async throws -> [LocalPlaybackSession] {
		let context = self.context
		return try await context.perform {
			try ManagedAnalyticsSession.all(in: context).map(\.local)
		}
	}

	public func deleteSession(_ sessionID: UUID) async throws {
		let context = self.context
		try await context.perform {
			guard let managed = try ManagedAnalyticsSession.first(with: sessionID, in: context) else { return }
			context.delete(managed)
			try context.save()
		}
	}

	public func deleteAllSessions() async throws {
		let context = self.context
		try await context.perform {
			try ManagedAnalyticsSession.all(in: context).forEach(context.delete)
			try context.save()
		}
	}

	static func enforceRetention(maxSessions: Int, in context: NSManagedObjectContext) {
		guard let sessions = try? ManagedAnalyticsSession.all(in: context), sessions.count > maxSessions else { return }
		let overflow = sessions.count - maxSessions
		sessions.prefix(overflow).forEach(context.delete)
	}
}
