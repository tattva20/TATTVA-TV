//
//  CoreDataAnalyticsStore.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import CoreData

public final class CoreDataAnalyticsStore: @unchecked Sendable {
	private static let modelName = "AnalyticsStore"

	@MainActor
	private static let model = NSManagedObjectModel.with(name: modelName, in: Bundle(for: CoreDataAnalyticsStore.self))

	private let container: NSPersistentContainer
	let context: NSManagedObjectContext
	let maxSessions: Int

	public enum StoreError: Error {
		case modelNotFound
		case failedToLoadPersistentContainer(Error)
	}

	@MainActor
	public convenience init(storeURL: URL, maxSessions: Int = 50) throws {
		guard let model = CoreDataAnalyticsStore.model else {
			throw StoreError.modelNotFound
		}

		try self.init(storeURL: storeURL, maxSessions: maxSessions, model: model)
	}

	public init(storeURL: URL, maxSessions: Int = 50, model: NSManagedObjectModel) throws {
		do {
			container = try NSPersistentContainer.load(name: CoreDataAnalyticsStore.modelName, model: model, url: storeURL)
			context = container.newBackgroundContext()
			self.maxSessions = maxSessions
		} catch {
			throw StoreError.failedToLoadPersistentContainer(error)
		}
	}

	private func cleanUpReferencesToPersistentStores() {
		context.performAndWait {
			let coordinator = self.container.persistentStoreCoordinator
			try? coordinator.persistentStores.forEach(coordinator.remove)
		}
	}

	deinit {
		cleanUpReferencesToPersistentStores()
	}
}
