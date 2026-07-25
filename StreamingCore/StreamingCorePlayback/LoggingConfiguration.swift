//
//  LoggingConfiguration.swift
//  StreamingCorePlayback
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import StreamingCore

/// Configures logging based on build environment.
/// Debug builds use console + OSLog, Release builds use OSLog only with info+ level.
public enum LoggingConfiguration {

	/// Creates a logger appropriate for the current build environment.
	/// - Parameter subsystem: The composition root's subsystem (e.g. the app's bundle identifier).
	public static func makeLogger(subsystem: String) -> any Logger {
		#if DEBUG
		return makeDebugLogger(subsystem: subsystem)
		#else
		return makeReleaseLogger(subsystem: subsystem)
		#endif
	}

	/// Creates a logger for debug builds - verbose console output
	private static func makeDebugLogger(subsystem: String) -> any Logger {
		let consoleLogger = ConsoleLogger(minimumLevel: .debug)
		let osLogLogger = OSLogLogger(
			subsystem: subsystem,
			category: "VideoPlayer",
			minimumLevel: .debug
		)

		return CompositeLogger(
			loggers: [consoleLogger, osLogLogger],
			minimumLevel: .debug
		)
	}

	/// Creates a logger for release builds - only important events
	private static func makeReleaseLogger(subsystem: String) -> any Logger {
		OSLogLogger(
			subsystem: subsystem,
			category: "VideoPlayer",
			minimumLevel: .info
		)
	}

	/// Creates a null logger for testing or when logging is disabled
	public static func makeNullLogger() -> any Logger {
		NullLogger()
	}
}
