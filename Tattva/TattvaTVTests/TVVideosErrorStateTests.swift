import XCTest
import UIKit
import StreamingCore
import StreamingCoreAccessibility
@testable import TattvaTV

@MainActor
final class TVVideosErrorStateTests: XCTestCase {
	override func tearDown() {
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	func test_loadFailure_displaysErrorAndRendersNoPosters() async {
		let sut = makeSUT(videoResult: .failure(anyError()))

		sut.simulateAppearance()

		await eventually { sut.errorMessage != nil }
		XCTAssertNotNil(sut.errorMessage, "Expected an error message when the video list fails to load")
		XCTAssertNotNil(sut.retryButton, "Expected a focusable retry affordance on failure")
		XCTAssertEqual(sut.numberOfRenderedPosters(), 0)
	}

	func test_successfulLoad_displaysNoError() async {
		let sut = makeSUT(videoResult: .success(paginated([makeVideo(title: "A")])))

		sut.simulateAppearance()

		await eventually { sut.numberOfRenderedPosters() == 1 }
		XCTAssertNil(sut.errorMessage, "Expected no error message on a successful load")
		XCTAssertFalse(sut.isLoadingIndicatorVisible, "Expected the loading indicator to clear after load")
	}

	func test_retryAfterFailure_reloadsAndRendersVideos() async {
		let loader = LoaderStub(results: [
			.failure(anyError()),
			.success(paginated([makeVideo(title: "Recovered")]))
		])
		let sut = TVVideosUIComposer.videosComposedWith(
			videoLoader: { try loader.next() },
			imageLoader: { _ in Data() },
			selection: { _ in })

		sut.simulateAppearance()
		await eventually { sut.errorMessage != nil }

		sut.simulateRetry()

		await eventually { sut.numberOfRenderedPosters() == 1 }
		XCTAssertNil(sut.errorMessage, "Expected the error to clear after a successful retry")
		XCTAssertEqual(sut.posterTitle(at: 0), "Recovered")
	}

	func test_loadFailure_announcesErrorForVoiceOver() async {
		let announcer = AnnouncerSpy()
		let videosViewController = TVVideosViewController()
		let adapter = TVVideosLoaderPresentationAdapter(
			videoLoader: { throw self.anyError() },
			imageLoader: { _ in Data() },
			selection: { _ in })
		adapter.videosViewController = videosViewController
		adapter.announcer = announcer
		videosViewController.loadViewIfNeeded()

		adapter.loadVideos()

		await eventually { !announcer.messages.isEmpty }
		XCTAssertEqual(announcer.messages.last, videosViewController.errorMessage)
	}

	// MARK: - Helpers

	private func makeSUT(
		videoResult: Result<Paginated<Video>, Error>,
		imageLoader: @escaping @Sendable (URL) async throws -> Data = { _ in Data() }
	) -> TVVideosViewController {
		TVVideosUIComposer.videosComposedWith(
			videoLoader: { try videoResult.get() },
			imageLoader: imageLoader,
			selection: { _ in })
	}

	private func eventually(_ condition: () -> Bool, iterations: Int = 100) async {
		for _ in 0..<iterations {
			if condition() { return }
			await Task.yield()
		}
	}

	private func paginated(_ videos: [Video]) -> Paginated<Video> {
		Paginated(items: videos)
	}

	private func anyError() -> NSError {
		NSError(domain: "test", code: 0)
	}

	private func makeVideo(title: String) -> Video {
		Video(
			id: UUID(),
			title: title,
			description: nil,
			url: URL(string: "https://any-url.com/\(title).m3u8")!,
			thumbnailURL: URL(string: "https://any-url.com/\(title).jpg")!,
			duration: 0)
	}
}

@MainActor
private final class LoaderStub {
	private var results: [Result<Paginated<Video>, Error>]

	init(results: [Result<Paginated<Video>, Error>]) {
		self.results = results
	}

	func next() throws -> Paginated<Video> {
		let result = results.count > 1 ? results.removeFirst() : results[0]
		return try result.get()
	}
}

@MainActor
private final class AnnouncerSpy: Announcer {
	private(set) var messages: [String] = []

	func announce(_ message: String) {
		messages.append(message)
	}
}

@MainActor
extension TVVideosViewController {
	func simulateRetry() {
		retryButton?.sendActions(for: .primaryActionTriggered)
	}
}
