import Combine
import UIKit
import StreamingCore
import StreamingCoreiOS

final class PerformanceAlertLoggingBinding {
	private let cancellable: AnyCancellable

	init(alerts: AnyPublisher<PerformanceAlert, Never>, logger: any Logger) {
		cancellable = alerts.sink { alert in
			logger.warning(alert.message)
		}
	}
}
