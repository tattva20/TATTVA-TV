//
//  LoadResourcePresentationAdapterTests.swift
//  TattvaTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore
@testable import Tattva

@MainActor
final class LoadResourcePresentationAdapterTests: XCTestCase {

	override func tearDown() {
		super.tearDown()
		for _ in 0..<3 {
			RunLoop.current.run(until: Date())
		}
	}

	func test_init_doesNotLoadResource() {
		var loadCount = 0
		_ = makeSUT(loader: makeHangingLoader(loadHandler: { loadCount += 1 }))

		XCTAssertEqual(loadCount, 0, "Expected no loading before load is requested")
	}

	func test_loadResource_notifiesLoadingStartOnEachLoad() {
		let presenter = LoadingViewSpy()
		let sut = makeSUT(loader: makeHangingLoader(), presenter: presenter)

		sut.loadResource()
		sut.didCancelImageRequest()
		sut.loadResource()

		XCTAssertEqual(presenter.loadingCallCount, 2, "Expected loading notification on each load attempt")
	}

	func test_loadResource_deliversResourceOnSuccess() async {
		let expectedResource = "test resource"
		let presenter = LoadingViewSpy()
		let sut = makeSUT(loader: { expectedResource }, presenter: presenter)

		sut.loadResource()
		await poll(until: { presenter.receivedResources.count == 1 })

		XCTAssertEqual(presenter.receivedResources, [expectedResource])
		XCTAssertEqual(presenter.loadingStates.last, false, "Expected loading to stop after success")
	}

	func test_loadResource_deliversErrorOnFailure() async {
		let presenter = LoadingViewSpy()
		let sut = makeSUT(loader: { throw self.anyNSError() }, presenter: presenter)

		sut.loadResource()
		await poll(until: { presenter.errorCallCount == 1 })

		XCTAssertEqual(presenter.errorCallCount, 1)
		XCTAssertEqual(presenter.loadingStates.last, false, "Expected loading to stop after failure")
	}

	func test_didCancelImageRequest_allowsNewLoadAfterCancellation() {
		var loadCount = 0
		let sut = makeSUT(loader: makeHangingLoader(loadHandler: { loadCount += 1 }))

		sut.loadResource()
		XCTAssertEqual(loadCount, 1, "Expected first load attempt")

		sut.didCancelImageRequest()
		sut.loadResource()
		XCTAssertEqual(loadCount, 2, "Expected new load attempt after cancellation")
	}

	// MARK: - Helpers

	private func makeSUT(
		loader: @escaping () async throws -> String,
		presenter: LoadingViewSpy? = nil,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> AsyncLoadResourcePresentationAdapter<String, ResourceViewSpy> {
		let sut = AsyncLoadResourcePresentationAdapter<String, ResourceViewSpy>(loader: loader)
		let loadingSpy = presenter ?? LoadingViewSpy()
		let resourceView = ResourceViewSpy(loadingSpy: loadingSpy)
		sut.presenter = LoadResourcePresenter(
			resourceView: resourceView,
			loadingView: loadingSpy,
			errorView: loadingSpy
		)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}


	private func makeHangingLoader(loadHandler: @escaping () -> Void = {}) -> () async throws -> String {
		return {
			loadHandler()
			try await Task.sleep(nanoseconds: .max)
			return "unused"
		}
	}

	private func anyNSError() -> NSError {
		NSError(domain: "test", code: 0)
	}

	@MainActor
	private final class ResourceViewSpy: ResourceView {
		private(set) var displayedResources: [String] = []
		private weak var loadingSpy: LoadingViewSpy?

		init(loadingSpy: LoadingViewSpy? = nil) {
			self.loadingSpy = loadingSpy
		}

		func display(_ viewModel: String) {
			displayedResources.append(viewModel)
			loadingSpy?.recordResource(viewModel)
		}
	}

	@MainActor
	private final class LoadingViewSpy: ResourceLoadingView, ResourceErrorView {
		private(set) var loadingCallCount = 0
		private(set) var loadingStates: [Bool] = []
		private(set) var errorCallCount = 0
		private(set) var receivedResources: [String] = []

		func display(_ viewModel: ResourceLoadingViewModel) {
			loadingCallCount += 1
			loadingStates.append(viewModel.isLoading)
		}

		func display(_ viewModel: ResourceErrorViewModel) {
			if viewModel.message != nil {
				errorCallCount += 1
			}
		}

		func recordResource(_ resource: String) {
			receivedResources.append(resource)
		}
	}
}
