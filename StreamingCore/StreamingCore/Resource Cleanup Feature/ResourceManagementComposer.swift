//
//  ResourceManagementComposer.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//
import Combine

@MainActor
public enum ResourceManagementComposer {
	public static func makeCoordinator(
		deleteCachedVideos: @escaping () throws -> Void,
		memoryMonitor: MemoryMonitor
	) -> ResourceCleanupCoordinator {
		let cleaner = VideoCacheCleaner(deleteAction: deleteCachedVideos)
		return ResourceCleanupCoordinator(cleaners: [cleaner], memoryMonitor: memoryMonitor)
	}

	public static func bindBufferManagerToMemory(
		memoryMonitor: MemoryMonitor,
		bufferManager: any BufferManager
	) -> AnyCancellable {
		memoryMonitor.statePublisher.sink { [bufferManager] state in
			bufferManager.updateMemoryState(state)
		}
	}
}
