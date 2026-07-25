import XCTest
import AVFoundation
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

	// MARK: - Helpers

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
