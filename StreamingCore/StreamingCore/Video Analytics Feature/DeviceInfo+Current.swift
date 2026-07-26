//
//  DeviceInfo+Current.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//
import Foundation

public extension DeviceInfo {
	static func current(networkType: String? = nil) -> DeviceInfo {
		DeviceInfo(
			model: currentModelIdentifier(),
			osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
			networkType: networkType
		)
	}

	private static func currentModelIdentifier() -> String {
		var systemInfo = utsname()
		uname(&systemInfo)
		let identifier = withUnsafePointer(to: &systemInfo.machine) { pointer in
			pointer.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
		}
		return identifier.isEmpty ? "Unknown" : identifier
	}
}

public enum AppVersion {
	public static var current: String {
		Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
	}
}
