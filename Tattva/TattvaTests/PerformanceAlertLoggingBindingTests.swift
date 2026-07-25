import XCTest
import Combine
import StreamingCore
@testable import Tattva

@MainActor
final class PerformanceAlertLoggingBindingTests: XCTestCase {

	func test_forwardsAlertMessageToLoggerAsWarning() {
		let subject = PassthroughSubject<PerformanceAlert, Never>()
		let logger = LoggerSpy()
		let sut = PerformanceAlertLoggingBinding(alerts: subject.eraseToAnyPublisher(), logger: logger)

		subject.send(makeAlert(message: "Frequent rebuffering detected"))

		XCTAssertEqual(logger.loggedMessages, ["Frequent rebuffering detected"])
		XCTAssertEqual(logger.loggedLevels, [.warning])
		_ = sut
	}

	func test_forwardsEachAlert() {
		let subject = PassthroughSubject<PerformanceAlert, Never>()
		let logger = LoggerSpy()
		let sut = PerformanceAlertLoggingBinding(alerts: subject.eraseToAnyPublisher(), logger: logger)

		subject.send(makeAlert(message: "one"))
		subject.send(makeAlert(message: "two"))

		XCTAssertEqual(logger.loggedMessages, ["one", "two"])
		_ = sut
	}

	func test_deallocation_stopsForwarding() {
		let subject = PassthroughSubject<PerformanceAlert, Never>()
		let logger = LoggerSpy()
		var sut: PerformanceAlertLoggingBinding? = PerformanceAlertLoggingBinding(alerts: subject.eraseToAnyPublisher(), logger: logger)

		sut = nil
		subject.send(makeAlert(message: "after release"))

		XCTAssertTrue(logger.loggedMessages.isEmpty, "Expected no forwarding once the binding is released")
	}

	// MARK: - Helpers

	private func makeAlert(message: String) -> PerformanceAlert {
		PerformanceAlert(
			id: UUID(),
			sessionID: UUID(),
			type: .playbackStalled,
			severity: .warning,
			timestamp: Date(),
			message: message,
			suggestion: nil)
	}

	private final class LoggerSpy: Logger, @unchecked Sendable {
		let minimumLevel: LogLevel = .debug

		private let lock = NSLock()
		private var _entries: [LogEntry] = []

		var loggedMessages: [String] {
			lock.lock(); defer { lock.unlock() }
			return _entries.map(\.message)
		}

		var loggedLevels: [LogLevel] {
			lock.lock(); defer { lock.unlock() }
			return _entries.map(\.level)
		}

		func log(_ entry: LogEntry) {
			lock.lock(); defer { lock.unlock() }
			_entries.append(entry)
		}
	}
}
