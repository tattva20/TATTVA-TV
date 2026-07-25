//
//  ManagedAnalyticsSession.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import CoreData
import Foundation

@objc(ManagedAnalyticsSession)
final class ManagedAnalyticsSession: NSManagedObject {
	@NSManaged var id: UUID
	@NSManaged var videoID: UUID
	@NSManaged var videoTitle: String
	@NSManaged var startTime: Date
	@NSManaged var endTime: Date?
	@NSManaged var deviceModel: String
	@NSManaged var osVersion: String
	@NSManaged var networkType: String?
	@NSManaged var appVersion: String
	@NSManaged var events: NSOrderedSet
}

extension ManagedAnalyticsSession {
	static func first(with id: UUID, in context: NSManagedObjectContext) throws -> ManagedAnalyticsSession? {
		let request = NSFetchRequest<ManagedAnalyticsSession>(entityName: entity().name!)
		request.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(ManagedAnalyticsSession.id), id as NSUUID])
		request.returnsObjectsAsFaults = false
		request.fetchLimit = 1
		return try context.fetch(request).first
	}

	static func all(in context: NSManagedObjectContext) throws -> [ManagedAnalyticsSession] {
		let request = NSFetchRequest<ManagedAnalyticsSession>(entityName: entity().name!)
		request.returnsObjectsAsFaults = false
		request.sortDescriptors = [NSSortDescriptor(key: #keyPath(ManagedAnalyticsSession.startTime), ascending: true)]
		return try context.fetch(request)
	}

	func update(from local: LocalPlaybackSession) {
		id = local.id
		videoID = local.videoID
		videoTitle = local.videoTitle
		startTime = local.startTime
		endTime = local.endTime
		deviceModel = local.deviceModel
		osVersion = local.osVersion
		networkType = local.networkType
		appVersion = local.appVersion
	}

	var local: LocalPlaybackSession {
		LocalPlaybackSession(
			id: id,
			videoID: videoID,
			videoTitle: videoTitle,
			startTime: startTime,
			endTime: endTime,
			deviceModel: deviceModel,
			osVersion: osVersion,
			networkType: networkType,
			appVersion: appVersion)
	}

	var localEvents: [LocalPlaybackEvent] {
		(events.array as? [ManagedAnalyticsEvent])?.map(\.local) ?? []
	}
}
