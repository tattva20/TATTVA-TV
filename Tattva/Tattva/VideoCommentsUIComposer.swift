//
//  VideoCommentsUIComposer.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreiOS
import StreamingCoreAccessibility

@MainActor
public enum VideoCommentsUIComposer {
	private typealias CommentsPresentationAdapter = AsyncLoadResourcePresentationAdapter<[VideoComment], AnnouncingResourceView<VideoCommentsViewAdapter>>

	public static func commentsComposedWith(
		commentsLoader: @MainActor @escaping () async throws -> [VideoComment]
	) -> ListViewController {
		let presentationAdapter = CommentsPresentationAdapter(loader: commentsLoader)

		let commentsController = makeCommentsViewController()
		commentsController.onRefresh = presentationAdapter.loadResource

		presentationAdapter.presenter = LoadResourcePresenter(
			resourceView: AnnouncingResourceView(
				decoratee: VideoCommentsViewAdapter(controller: commentsController),
				announcer: UIKitAnnouncer(),
				describe: { "\($0.comments.count) comments" }),
			loadingView: WeakRefVirtualProxy(commentsController),
			errorView: WeakRefVirtualProxy(commentsController),
			mapper: { VideoCommentsPresenter.map($0) })

		return commentsController
	}

	private static func makeCommentsViewController() -> ListViewController {
		let bundle = Bundle(for: ListViewController.self)
		let storyboard = UIStoryboard(name: "VideoComments", bundle: bundle)
		let commentsController = storyboard.instantiateInitialViewController() as! ListViewController
		commentsController.title = VideoCommentsPresenter.title
		return commentsController
	}
}
