import XCTest
import AVFoundation
import Combine
import StreamingCore
import StreamingCorePlayback
@testable import TattvaTV

@MainActor
final class TVPlayerComposerTests: XCTestCase {

	func test_playerComposedWithVideo_loadsVideoURLIntoAVPlayer() {
		let url = anyStreamURL()

		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo(url: url))

		let loadedURL = (bundle.player.currentItem?.asset as? AVURLAsset)?.url
		XCTAssertEqual(loadedURL, url, "Expected the composed AVPlayer to be loaded with the video's stream URL")
	}

	func test_playerComposedWithVideo_startsCoordinatorObservingPlayer() {
		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo())

		XCTAssertTrue(bundle.coordinator.isObserving, "Expected the playback coordinator to start observing on composition")
	}

	func test_playerComposedWith_wiresBufferAdapter_whenBufferManagerProvided() {
		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo(), bufferManager: AdaptiveBufferManager())

		XCTAssertNotNil(bundle.bufferAdapter, "Expected a buffer adapter wired to the tvOS player when a buffer manager is provided")
	}

	func test_playerComposedWith_omitsBufferAdapter_whenNoBufferManager() {
		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo())

		XCTAssertNil(bundle.bufferAdapter, "Expected no buffer adapter when no buffer manager is provided")
	}

	func test_playerComposedWith_deliversNetworkQualityToBufferManager() {
		let bufferManager = BufferManagerSpy()
		let expectation = expectation(description: "buffer manager receives a network-quality update")
		expectation.assertForOverFulfill = false
		bufferManager.onUpdateNetworkQuality = { _ in expectation.fulfill() }

		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo(), bufferManager: bufferManager)

		wait(for: [expectation], timeout: 2.0)
		XCTAssertFalse(
			bufferManager.receivedNetworkQualities.isEmpty,
			"Expected the composed tvOS network monitor to drive the buffer manager's network quality")
		_ = bundle
	}

	func test_playerComposedWith_appliesLoggingDecorator_whenStructuredLoggerProvided() async {
		let logger = LoggerSpy()

		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo(), structuredLogger: logger)
		bundle.statefulPlayer.play()

		await poll(until: { !logger.loggedMessages.isEmpty })
		XCTAssertFalse(
			logger.loggedMessages.isEmpty,
			"Expected the composed tvOS player to log through the injected logging decorator")
	}

	func test_playerComposedWith_wiresMemoryPerformanceBinding_whenPublisherProvided() {
		let subject = PassthroughSubject<MemoryState, Never>()

		let bundle = TVPlayerComposer.playerComposedWith(
			video: makeVideo(),
			memoryStatePublisher: subject.eraseToAnyPublisher())

		XCTAssertNotNil(bundle.memoryPerformanceCancellable, "Expected a memory-performance binding when a publisher is provided")
	}

	func test_playerComposedWith_omitsMemoryPerformanceBinding_whenNoPublisher() {
		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo())

		XCTAssertNil(bundle.memoryPerformanceCancellable, "Expected no memory-performance binding without a publisher")
	}

	func test_playerComposedWith_wiresPerformanceAlertLogging_whenStructuredLoggerProvided() {
		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo(), structuredLogger: LoggerSpy())

		XCTAssertNotNil(bundle.performanceAlertLogging, "Expected a performance-alert logging binding when a structured logger is provided")
	}

	// MARK: - Helpers

	@discardableResult
	private func poll(until condition: @MainActor () -> Bool, timeout: TimeInterval = 1) async -> Bool {
		let deadline = Date() + timeout
		while Date() < deadline {
			if condition() { return true }
			await Task.yield()
		}
		return condition()
	}

	private final class LoggerSpy: Logger, @unchecked Sendable {
		let minimumLevel: LogLevel = .debug

		private let lock = NSLock()
		private var _entries: [LogEntry] = []

		var loggedMessages: [String] {
			lock.lock(); defer { lock.unlock() }
			return _entries.map(\.message)
		}

		func log(_ entry: LogEntry) {
			lock.lock(); defer { lock.unlock() }
			_entries.append(entry)
		}
	}

	@MainActor
	private final class BufferManagerSpy: BufferManager {
		private(set) var receivedNetworkQualities: [NetworkQuality] = []
		private(set) var receivedMemoryStates: [MemoryState] = []
		var onUpdateNetworkQuality: ((NetworkQuality) -> Void)?

		private let subject = CurrentValueSubject<BufferConfiguration, Never>(.balanced)
		var currentConfiguration: BufferConfiguration { subject.value }
		var configurationPublisher: AnyPublisher<BufferConfiguration, Never> { subject.eraseToAnyPublisher() }

		func updateMemoryState(_ state: MemoryState) {
			receivedMemoryStates.append(state)
		}

		func updateNetworkQuality(_ quality: NetworkQuality) {
			receivedNetworkQualities.append(quality)
			onUpdateNetworkQuality?(quality)
		}
	}

	private func makeVideo(url: URL = URL(string: "https://any-url.com/stream.m3u8")!) -> Video {
		Video(
			id: UUID(),
			title: "any title",
			description: nil,
			url: url,
			thumbnailURL: URL(string: "https://any-url.com/thumb.jpg")!,
			duration: 0
		)
	}

	private func anyStreamURL() -> URL {
		URL(string: "https://a-given-host.com/a-given-stream.m3u8")!
	}
}
