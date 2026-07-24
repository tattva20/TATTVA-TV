//
//  VideosUIIntegrationTests.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore
import StreamingCoreiOS
import Tattva

@MainActor
class VideosUIIntegrationTests: XCTestCase {

	func test_videoView_hasTitle() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.title, VideosPresenter.title)
	}

	func test_videoSelection_notifiesHandler() async {
		let video0 = makeVideo()
		let video1 = makeVideo()
		var selectedVideos = [Video]()
		let (sut, loader) = makeSUT(selection: { selectedVideos.append($0) })

		sut.simulateAppearance()
		await loader.completeLoading(with: [video0, video1], at: 0)
		sut.tableView.enforceLayoutCycle()

		sut.simulateTapOnVideoView(at: 0)
		XCTAssertEqual(selectedVideos, [video0])

		sut.simulateTapOnVideoView(at: 1)
		XCTAssertEqual(selectedVideos, [video0, video1])
	}

	func test_loadVideoActions_requestVideosFromLoader() async {
		let (sut, loader) = makeSUT()
		XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view appears")

		sut.simulateAppearance()
		XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view appears")

		await loader.completeLoading(at: 0)
		sut.simulateUserInitiatedReload()
		XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a reload")

		await loader.completeLoading(at: 1)
		sut.simulateUserInitiatedReload()
		XCTAssertEqual(loader.loadCallCount, 3, "Expected yet another loading request once user initiates another reload")
	}

	func test_loadVideoActions_runsAutomaticallyOnlyOnFirstAppearance() {
		let (sut, loader) = makeSUT()
		XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view appears")

		sut.simulateAppearance()
		XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view appears")

		sut.simulateAppearance()
		XCTAssertEqual(loader.loadCallCount, 1, "Expected no loading request the second time view appears")
	}

	func test_loadingVideoIndicator_isVisibleWhileLoadingVideos() async {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view appears")

		await loader.completeLoading(at: 0)
		XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfully")

		sut.simulateUserInitiatedReload()
		XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")

		await loader.completeLoadingWithError(at: 1)
		XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated loading completes with error")
	}

	func test_loadVideoCompletion_rendersSuccessfullyLoadedVideos() async {
		let video0 = makeVideo(title: "a title", description: "a description")
		let video1 = makeVideo(title: "another title", description: "another description")
		let video2 = makeVideo(title: "yet another title", description: "yet another description")
		let video3 = makeVideo(title: "and another title", description: "and another description")
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		assertThat(sut, isRendering: [])

		await loader.completeLoading(with: [video0], at: 0)
		assertThat(sut, isRendering: [video0])

		sut.simulateUserInitiatedReload()
		await loader.completeLoading(with: [video0, video1, video2, video3], at: 1)
		assertThat(sut, isRendering: [video0, video1, video2, video3])
	}

	func test_videoView_isAccessibleAsAButtonLabeledWithTitleAndDescription() async {
		let video = makeVideo(title: "Big Buck Bunny", description: "A rabbit")
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		await loader.completeLoading(with: [video], at: 0)

		let cell = sut.videoView(at: 0)
		XCTAssertEqual(cell?.isAccessibilityElement, true, "The feed cell should be a single VoiceOver element")
		XCTAssertEqual(cell?.accessibilityLabel, "Big Buck Bunny. A rabbit")
		XCTAssertEqual(cell?.accessibilityTraits.contains(.button), true, "Selecting a video plays it, so the cell should read as a button")
	}

	func test_loadVideoCompletion_rendersSuccessfullyLoadedEmptyVideosAfterNonEmptyVideos() async {
		let video = makeVideo()
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		await loader.completeLoading(with: [video], at: 0)
		sut.tableView.enforceLayoutCycle()
		assertThat(sut, isRendering: [video])

		sut.simulateUserInitiatedReload()
		await loader.completeLoading(with: [], at: 1)
		sut.tableView.enforceLayoutCycle()
		assertThat(sut, isRendering: [])
	}

	func test_loadVideoCompletion_doesNotAlterCurrentRenderingStateOnError() async {
		let video0 = makeVideo()
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		await loader.completeLoading(with: [video0], at: 0)
		assertThat(sut, isRendering: [video0])

		sut.simulateUserInitiatedReload()
		await loader.completeLoadingWithError(at: 1)
		assertThat(sut, isRendering: [video0])
	}

	func test_loadVideoCompletion_rendersErrorMessageOnErrorUntilNextReload() async {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertEqual(sut.errorMessage, nil)

		await loader.completeLoadingWithError(at: 0)
		XCTAssertEqual(sut.errorMessage, loadError)

		sut.simulateUserInitiatedReload()
		XCTAssertEqual(sut.errorMessage, nil)
	}

	func test_tapOnErrorView_hidesErrorMessage() async {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertEqual(sut.errorMessage, nil)

		await loader.completeLoadingWithError(at: 0)
		XCTAssertEqual(sut.errorMessage, loadError)

		sut.simulateTapOnErrorMessage()
		XCTAssertEqual(sut.errorMessage, nil)
	}

	func test_loadMoreActions_requestMoreFromLoader() async {
		let (sut, loader) = makeSUT()
		sut.simulateAppearance()
		await loader.completeLoading(with: [makeVideo()])

		XCTAssertEqual(loader.loadMoreCallCount, 0, "Expected no requests before until load more action")

		sut.simulateLoadMoreAction()
		XCTAssertEqual(loader.loadMoreCallCount, 1, "Expected load more request")

		sut.simulateLoadMoreAction()
		XCTAssertEqual(loader.loadMoreCallCount, 1, "Expected no request while loading more")

		await loader.completeLoadMore(lastPage: false, at: 0)
		sut.simulateLoadMoreAction()
		XCTAssertEqual(loader.loadMoreCallCount, 2, "Expected request after load more completed with more pages")

		await loader.completeLoadMoreWithError(at: 1)
		sut.simulateLoadMoreAction()
		XCTAssertEqual(loader.loadMoreCallCount, 3, "Expected request after load more failure")

		await loader.completeLoadMore(lastPage: true, at: 2)
		sut.simulateLoadMoreAction()
		XCTAssertEqual(loader.loadMoreCallCount, 3, "Expected no request after loading all pages")
	}

	func test_loadingMoreIndicator_isVisibleWhileLoadingMore() async {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertFalse(sut.isShowingLoadMoreIndicator, "Expected no load more indicator when more pages not available")

		await loader.completeLoading(with: [makeVideo()], at: 0)
		sut.tableView.enforceLayoutCycle()
		XCTAssertFalse(sut.isShowingLoadMoreIndicator, "Expected no load more indicator once loading completes successfully")

		sut.simulateLoadMoreAction()
		sut.tableView.enforceLayoutCycle()
		XCTAssertTrue(sut.isShowingLoadMoreIndicator, "Expected load more indicator on load more action")

		await loader.completeLoadMore(with: [makeVideo()], at: 0)
		sut.tableView.enforceLayoutCycle()
		XCTAssertFalse(sut.isShowingLoadMoreIndicator, "Expected no load more indicator after load more completes with success")

		sut.simulateLoadMoreAction()
		sut.tableView.enforceLayoutCycle()
		XCTAssertTrue(sut.isShowingLoadMoreIndicator, "Expected load more indicator on second load more action")

		await loader.completeLoadMoreWithError(at: 1)
		sut.tableView.enforceLayoutCycle()
		XCTAssertFalse(sut.isShowingLoadMoreIndicator, "Expected no load more indicator after load more completes with error")
	}

	func test_loadMoreCompletion_rendersErrorMessageOnError() async {
		let (sut, loader) = makeSUT()
		sut.simulateAppearance()
		await loader.completeLoading()

		sut.simulateLoadMoreAction()
		XCTAssertNil(sut.loadMoreErrorMessage, "Expected no error message on load more action")

		await loader.completeLoadMoreWithError(at: 0)
		XCTAssertEqual(sut.loadMoreErrorMessage, loadError, "Expected error message after load more failure")

		sut.simulateLoadMoreAction()
		XCTAssertNil(sut.loadMoreErrorMessage, "Expected no error message on retry action")
	}

	func test_tapOnLoadMoreErrorView_loadsMore() async {
		let (sut, loader) = makeSUT()
		sut.simulateAppearance()
		await loader.completeLoading()

		sut.simulateLoadMoreAction()
		XCTAssertEqual(loader.loadMoreCallCount, 1)

		sut.simulateTapOnLoadMoreError()
		XCTAssertEqual(loader.loadMoreCallCount, 1)

		await loader.completeLoadMoreWithError()
		sut.simulateTapOnLoadMoreError()
		XCTAssertEqual(loader.loadMoreCallCount, 2)
	}

	func test_videoImageView_loadsImageURLWhenVisible() async {
		let video0 = makeVideo(thumbnailURL: URL(string: "http://url-0.com")!)
		let video1 = makeVideo(thumbnailURL: URL(string: "http://url-1.com")!)
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until views become visible")

		await loader.completeLoading(with: [video0, video1])
		sut.simulateVideoViewVisible(at: 0)
		XCTAssertEqual(loader.loadedImageURLs, [video0.thumbnailURL], "Expected first image URL request once first view becomes visible")

		sut.simulateVideoViewVisible(at: 1)
		XCTAssertEqual(loader.loadedImageURLs, [video0.thumbnailURL, video1.thumbnailURL], "Expected second image URL request once second view also becomes visible")
	}

	// MARK: - Helpers

	private func makeSUT(
		selection: @MainActor @escaping (Video) -> Void = { _ in },
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: ListViewController, loader: LoaderSpy) {
		let loader = LoaderSpy()

		let sut = VideosUIComposer.videosComposedWith(
			videoLoader: loader.load,
			imageLoader: loader.loadImageData,
			selection: selection
		)
		trackForMemoryLeaks(loader, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)

		addTeardownBlock { [weak loader] in
			await loader?.cancelPendingRequests()
		}

		return (sut, loader)
	}

	private func assertThat(_ sut: ListViewController, isRendering videos: [Video], file: StaticString = #filePath, line: UInt = #line) {
		XCTAssertEqual(sut.numberOfRenderedVideoViews(), videos.count, "videos count", file: file, line: line)

		videos.enumerated().forEach { index, video in
			assertThat(sut, hasViewConfiguredFor: video, at: index, file: file, line: line)
		}
	}

	private func assertThat(_ sut: ListViewController, hasViewConfiguredFor video: Video, at index: Int, file: StaticString = #filePath, line: UInt = #line) {
		let view = sut.videoView(at: index)

		guard let cell = view as? VideoCell else {
			return XCTFail("Expected \(VideoCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
		}

		XCTAssertEqual(cell.titleText, video.title, "Expected title text to be \(String(describing: video.title)) for video view at index (\(index))", file: file, line: line)
		XCTAssertEqual(cell.descriptionText, video.description, "Expected description text to be \(String(describing: video.description)) for video view at index (\(index))", file: file, line: line)
	}

	private func makeVideo(
		title: String = "any title",
		description: String = "any description",
		url: URL = URL(string: "https://any-url.com")!,
		thumbnailURL: URL = URL(string: "https://any-url.com/thumbnail.jpg")!
	) -> Video {
		return Video(
			id: UUID(),
			title: title,
			description: description,
			url: url,
			thumbnailURL: thumbnailURL,
			duration: 120
		)
	}

	private var loadError: String {
		LoadResourcePresenter<Any, DummyView>.loadError
	}

	private class DummyView: ResourceView {
		func display(_ viewModel: Any) {}
	}
}

private extension VideoCell {
	var titleText: String? {
		return titleLabel.text
	}

	var descriptionText: String? {
		return descriptionLabel.text
	}
}
