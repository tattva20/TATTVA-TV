//
//  ManagedAnalyticsEvent.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import CoreData
import Foundation

@objc(ManagedAnalyticsEvent)
final class ManagedAnalyticsEvent: NSManagedObject {
	@NSManaged var id: UUID
	@NSManaged var sessionID: UUID
	@NSManaged var videoID: UUID
	@NSManaged var eventType: String
	@NSManaged var eventData: Data?
	@NSManaged var timestamp: Date
	@NSManaged var currentPosition: TimeInterval
	@NSManaged var session: ManagedAnalyticsSession?
}

extension ManagedAnalyticsEvent {
	func update(from local: LocalPlaybackEvent) {
		id = local.id
		sessionID = local.sessionID
		videoID = local.videoID
		eventType = local.eventType
		eventData = local.eventData
		timestamp = local.timestamp
		currentPosition = local.currentPosition
	}

	var local: LocalPlaybackEvent {
		LocalPlaybackEvent(
			id: id,
			sessionID: sessionID,
			videoID: videoID,
			eventType: eventType,
			eventData: eventData,
			timestamp: timestamp,
			currentPosition: currentPosition)
	}
}
