//
//  ResourceCleanerSpy.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
@testable import StreamingCore

final class ResourceCleanerSpy: ResourceCleaner, @unchecked Sendable {
	let resourceName: String
	let priority: CleanupPriority

	private let lock = NSLock()
	private var _cleanupCallCount = 0
	private var _estimateCallCount = 0

	var cleanupCallCount: Int {
		lock.lock(); defer { lock.unlock() }
		return _cleanupCallCount
	}

	var estimateCallCount: Int {
		lock.lock(); defer { lock.unlock() }
		return _estimateCallCount
	}

	var stubEstimate: UInt64 = 1_000_000
	var stubResult: CleanupResult

	init(name: String = "Test Resource", priority: CleanupPriority = .medium) {
		self.resourceName = name
		self.priority = priority
		self.stubResult = CleanupResult(
			resourceName: name,
			bytesFreed: 1_000_000,
			itemsRemoved: 10,
			success: true
		)
	}

	func estimateCleanup() async -> UInt64 {
		lock.withLock { _estimateCallCount += 1 }
		return stubEstimate
	}

	func cleanup() async -> CleanupResult {
		lock.withLock { _cleanupCallCount += 1 }
		return stubResult
	}
}
