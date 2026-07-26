import XCTest
import UIKit
import StreamingCore
import StreamingCoreAccessibility
@testable import TattvaTV

@MainActor
final class TVVideosAnnouncerTests: XCTestCase {

	func test_loadVideos_announcesTheVideoCountForVoiceOver() async {
		let announcer = AnnouncerSpy()
		let sut = makeSUT(videos: [makeVideo(), makeVideo()], announcer: announcer)

		sut.loadVideos()

		await eventually { !announcer.announcements.isEmpty }
		XCTAssertEqual(announcer.announcements, ["2 videos"])
	}

	// MARK: - Helpers

	private func makeSUT(videos: [Video], announcer: Announcer) -> TVVideosLoaderPresentationAdapter {
		let sut = TVVideosLoaderPresentationAdapter(
			videoLoader: { Paginated(items: videos) },
			imageLoader: { _ in Data() },
			selection: { _ in })
		sut.announcer = announcer
		return sut
	}

	private func makeVideo() -> Video {
		Video(
			id: UUID(),
			title: "any",
			description: nil,
			url: URL(string: "https://a-host.com/a.m3u8")!,
			thumbnailURL: URL(string: "https://a-host.com/t.jpg")!,
			duration: 0)
	}

	private func eventually(_ condition: () -> Bool, iterations: Int = 100) async {
		for _ in 0..<iterations {
			if condition() { return }
			await Task.yield()
		}
	}

	private final class AnnouncerSpy: Announcer {
		private(set) var announcements = [String]()
		func announce(_ message: String) { announcements.append(message) }
	}
}
