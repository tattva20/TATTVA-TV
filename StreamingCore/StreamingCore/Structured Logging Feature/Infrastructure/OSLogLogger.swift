//
//  OSLogLogger.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import os.log
import StreamingCore

/// A logger that uses Apple's unified logging system (OSLog).
/// Integrates with Console.app and Instruments for debugging.
public final class OSLogLogger: StreamingCore.Logger, @unchecked Sendable {
	public let minimumLevel: LogLevel
	private let osLog: OSLog

	public init(
		subsystem: String,
		category: String,
		minimumLevel: LogLevel = .info
	) {
		self.minimumLevel = minimumLevel
		self.osLog = OSLog(subsystem: subsystem, category: category)
	}

	public func log(_ entry: LogEntry) {
		guard entry.level >= minimumLevel else { return }

		let osLogType: OSLogType
		switch entry.level {
		case .debug:
			osLogType = .debug
		case .info:
			osLogType = .info
		case .warning:
			osLogType = .default
		case .error:
			osLogType = .error
		case .critical:
			osLogType = .fault
		@unknown default:
			osLogType = .default
		}

		os_log("%{public}@", log: osLog, type: osLogType, entry.formattedMessage)
	}
}
