//
//  NetworkQualityMonitor.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation
import Network
import StreamingCore

/// Monitors network connectivity and quality using NWPathMonitor
public final class NetworkQualityMonitor: @unchecked Sendable {

	public enum ConnectionType: Sendable {
		case wifi
		case cellular
		case wiredEthernet
		case loopback
		case other
	}

	private let monitor: NWPathMonitor
	private let queue: DispatchQueue
	private var isMonitoring = false

	private let qualitySubject = CurrentValueSubject<NetworkQuality, Never>(.fair)

	public var currentQuality: NetworkQuality {
		qualitySubject.value
	}

	public var qualityPublisher: AnyPublisher<NetworkQuality, Never> {
		qualitySubject.eraseToAnyPublisher()
	}

	public init() {
		self.monitor = NWPathMonitor()
		self.queue = DispatchQueue(label: "com.streamingcore.networkmonitor", qos: .utility)
	}

	public func startMonitoring() async {
		guard !isMonitoring else { return }
		isMonitoring = true

		monitor.pathUpdateHandler = { [weak self] path in
			guard let self = self else { return }

			let connectionType = Self.connectionType(from: path)
			let quality = Self.determineQuality(
				status: path.status,
				isExpensive: path.isExpensive,
				isConstrained: path.isConstrained,
				connectionType: connectionType
			)

			self.qualitySubject.send(quality)
		}

		monitor.start(queue: queue)
	}

	public func stopMonitoring() async {
		guard isMonitoring else { return }
		isMonitoring = false
		monitor.cancel()
	}

	// MARK: - Quality Determination

	/// Determines network quality based on path properties
	/// - Parameters:
	///   - status: The network path status
	///   - isExpensive: Whether the connection is expensive (e.g., cellular)
	///   - isConstrained: Whether the connection is constrained (e.g., low data mode)
	///   - connectionType: The type of network connection
	/// - Returns: Estimated network quality
	public static func determineQuality(
		status: NWPath.Status,
		isExpensive: Bool,
		isConstrained: Bool,
		connectionType: ConnectionType
	) -> NetworkQuality {
		// Offline check
		guard status == .satisfied else {
			return .offline
		}

		// Constrained connections are poor quality
		if isConstrained {
			return .poor
		}

		// Base quality by connection type
		var quality: NetworkQuality
		switch connectionType {
		case .wifi, .wiredEthernet:
			quality = .excellent
		case .cellular:
			quality = .good
		case .loopback:
			quality = .excellent
		case .other:
			quality = .fair
		}

		// Reduce quality if expensive (metered connection)
		if isExpensive && quality > .fair {
			quality = .fair
		}

		return quality
	}

	// MARK: - Connection Type Detection

	private static func connectionType(from path: NWPath) -> ConnectionType {
		if path.usesInterfaceType(.wifi) {
			return .wifi
		} else if path.usesInterfaceType(.cellular) {
			return .cellular
		} else if path.usesInterfaceType(.wiredEthernet) {
			return .wiredEthernet
		} else if path.usesInterfaceType(.loopback) {
			return .loopback
		} else {
			return .other
		}
	}
}
