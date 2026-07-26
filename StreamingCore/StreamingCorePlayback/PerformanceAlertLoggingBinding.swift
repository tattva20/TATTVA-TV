//
//  PerformanceAlertLoggingBinding.swift
//  StreamingCorePlayback
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Combine
import StreamingCore

public final class PerformanceAlertLoggingBinding {
	private let cancellable: AnyCancellable

	public init(alerts: AnyPublisher<PerformanceAlert, Never>, logger: any Logger) {
		cancellable = alerts.sink { alert in
			logger.warning(alert.message)
		}
	}
}
