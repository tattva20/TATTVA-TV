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

private nonisolated(unsafe) var performanceAlertLoggingKey: UInt8 = 0

extension VideoPlayerViewController {
	var performanceAlertLogging: PerformanceAlertLoggingBinding? {
		get {
			objc_getAssociatedObject(self, &performanceAlertLoggingKey) as? PerformanceAlertLoggingBinding
		}
		set {
			objc_setAssociatedObject(
				self,
				&performanceAlertLoggingKey,
				newValue,
				.OBJC_ASSOCIATION_RETAIN_NONATOMIC
			)
		}
	}
}
