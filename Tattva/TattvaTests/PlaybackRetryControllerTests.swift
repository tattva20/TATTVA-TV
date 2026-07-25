import XCTest
@testable import StreamingCorePlayback

@MainActor
final class PlaybackRetryControllerTests: XCTestCase {

	func test_playbackDidFail_schedulesReloadAfterBaseDelay() {
		var scheduledDelay: TimeInterval?
		var scheduledWork: (@MainActor () -> Void)?
		var reloadCount = 0
		let sut = makeSUT(
			baseDelay: 2,
			schedule: { delay, work in scheduledDelay = delay; scheduledWork = work },
			reload: { reloadCount += 1 })

		sut.playbackDidFail()

		XCTAssertEqual(scheduledDelay, 2)
		XCTAssertEqual(reloadCount, 0, "Reload should wait for the scheduled delay")

		scheduledWork?()
		XCTAssertEqual(reloadCount, 1, "Reload should run when the scheduled work fires")
	}

	func test_repeatedFailures_useExponentialBackoff() {
		var delays: [TimeInterval] = []
		let sut = makeSUT(maxAttempts: 3, baseDelay: 1, schedule: { delay, _ in delays.append(delay) })

		sut.playbackDidFail()
		sut.playbackDidFail()
		sut.playbackDidFail()

		XCTAssertEqual(delays, [1, 2, 4])
	}

	func test_stopsRetrying_afterMaxAttempts() {
		var scheduleCount = 0
		let sut = makeSUT(maxAttempts: 2, schedule: { _, _ in scheduleCount += 1 })

		sut.playbackDidFail()
		sut.playbackDidFail()
		sut.playbackDidFail()
		sut.playbackDidFail()

		XCTAssertEqual(scheduleCount, 2, "Expected retries to stop after the maximum number of attempts")
	}

	func test_playbackDidRecover_resetsTheAttemptCount() {
		var delays: [TimeInterval] = []
		let sut = makeSUT(maxAttempts: 3, baseDelay: 1, schedule: { delay, _ in delays.append(delay) })

		sut.playbackDidFail()
		sut.playbackDidFail()
		sut.playbackDidRecover()
		sut.playbackDidFail()

		XCTAssertEqual(delays, [1, 2, 1], "Recovery should reset the backoff so the next failure starts from the base delay")
	}

	// MARK: - Helpers

	private func makeSUT(
		maxAttempts: Int = 3,
		baseDelay: TimeInterval = 1,
		schedule: @escaping (TimeInterval, @escaping @MainActor () -> Void) -> Void,
		reload: @escaping () -> Void = {},
		file: StaticString = #filePath,
		line: UInt = #line
	) -> PlaybackRetryController {
		let sut = PlaybackRetryController(
			maxAttempts: maxAttempts,
			baseDelay: baseDelay,
			schedule: schedule,
			reload: reload)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}
}
