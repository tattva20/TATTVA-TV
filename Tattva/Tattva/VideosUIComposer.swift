//
//  VideosUIComposer.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreiOS
import StreamingCoreAccessibility

@MainActor
public final class VideosUIComposer {
    private init() {}

    private typealias VideosPresentationAdapter = AsyncLoadResourcePresentationAdapter<Paginated<Video>, AnnouncingResourceView<VideosViewAdapter>>

    public static func videosComposedWith(
        videoLoader: @MainActor @escaping () async throws -> Paginated<Video>,
        imageLoader: @MainActor @escaping (URL) async throws -> Data,
        selection: @MainActor @escaping (Video) -> Void = { _ in }
    ) -> ListViewController {
        let presentationAdapter = VideosPresentationAdapter(loader: videoLoader)

        let videosController = makeVideosViewController()
        videosController.onRefresh = presentationAdapter.loadResource

        presentationAdapter.presenter = LoadResourcePresenter(
            resourceView: AnnouncingResourceView(
                decoratee: VideosViewAdapter(
                    controller: videosController,
                    imageLoader: imageLoader,
                    selection: selection),
                announcer: UIKitAnnouncer(),
                describe: { "\($0.items.count) videos" }),
            loadingView: WeakRefVirtualProxy(videosController),
            errorView: WeakRefVirtualProxy(videosController))

        return videosController
    }

    private static func makeVideosViewController() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Videos", bundle: bundle)
        let videosController = storyboard.instantiateInitialViewController() as! ListViewController
        videosController.title = VideosPresenter.title
        return videosController
    }
}

