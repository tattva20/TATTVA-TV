# Presenters and ViewModels

The Presentation layer provides clean separation between domain logic and UI, using Presenters for transformation logic and ViewModels as simple data structures for view consumption.

---

## Overview

```mermaid
flowchart TB
    subgraph Domain[Domain Models]
        DomainBox["Video<br/>Comment"]
    end
    subgraph Presenters
        VPP["VideoPlayerPresenter<br/><i>.map()</i>"]
        VIP["VideoImagePresenter<br/><i>.map()</i>"]
        LRP["LoadResourcePresenter<br/><i>didFinishLoading</i>"]
    end
    subgraph ViewModels
        VPVM[VideoPlayerViewModel]
        VIVM[VideoImageViewModel]
        RLVM[ResourceLoadingVM]
    end
    subgraph Views
        VPVC[VideoPlayerVC]
        VCell[VideoCell]
        LVC[ListViewController]
    end
    DomainBox --> VPP & VIP & LRP
    VPP --> VPVM
    VIP --> VIVM
    LRP --> RLVM
    VPVM & VIVM & RLVM --> Views

    classDef core fill:#e6f4ea,stroke:#34a853,color:#202124;
    classDef neutral fill:#fef7e0,stroke:#f9ab00,color:#202124;
    classDef app fill:#e8f0fe,stroke:#4285f4,color:#202124;
    class DomainBox core;
    class VPP,VIP,LRP,VPVM,VIVM,RLVM neutral;
    class VPVC,VCell,LVC app;
```

---

## Features

- **Dumb ViewModels** - Pure data structures with no logic
- **Smart Presenters** - Transformation and formatting logic
- **Generic ResourcePresenter** - Reusable loading/error handling
- **Protocol-Based Views** - Views conform to display protocols
- **Localized Strings** - Presenters handle localization
- **Testable Logic** - Presentation logic easily unit tested

---

## Shared Presentation

### LoadResourcePresenter

**File:** `StreamingCore/StreamingCore/Shared Presentation/LoadResourcePresenter.swift`

Generic presenter for loading any resource with consistent loading/error states.

```swift
@MainActor
public protocol ResourceView {
    associatedtype ResourceViewModel
    func display(_ viewModel: ResourceViewModel)
}

@MainActor
public final class LoadResourcePresenter<Resource, View: ResourceView> {
    public typealias Mapper = (Resource) throws -> View.ResourceViewModel

    private let resourceView: View
    private let loadingView: ResourceLoadingView
    private let errorView: ResourceErrorView
    private let mapper: Mapper

    public static var loadError: String {
        NSLocalizedString("GENERIC_CONNECTION_ERROR",
                          tableName: "Shared",
                          bundle: Bundle(for: Self.self),
                          comment: "Error message displayed when we can't load the resource from the server")
    }

    public init(resourceView: View, loadingView: ResourceLoadingView, errorView: ResourceErrorView, mapper: @escaping Mapper) {
        self.resourceView = resourceView
        self.loadingView = loadingView
        self.errorView = errorView
        self.mapper = mapper
    }

    // Convenience initializer when Resource == ViewModel (no mapping needed)
    public init(resourceView: View, loadingView: ResourceLoadingView, errorView: ResourceErrorView) where Resource == View.ResourceViewModel {
        self.resourceView = resourceView
        self.loadingView = loadingView
        self.errorView = errorView
        self.mapper = { $0 }
    }

    public func didStartLoading() {
        errorView.display(.noError)
        loadingView.display(ResourceLoadingViewModel(isLoading: true))
    }

    public func didFinishLoading(with resource: Resource) {
        do {
            resourceView.display(try mapper(resource))
            loadingView.display(ResourceLoadingViewModel(isLoading: false))
        } catch {
            didFinishLoading(with: error)
        }
    }

    public func didFinishLoading(with error: Error) {
        errorView.display(.error(message: Self.loadError))
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
    }
}
```

### View Protocols

**ResourceLoadingView:**
```swift
public protocol ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel)
}
```

**ResourceErrorView:**
```swift
public protocol ResourceErrorView {
    func display(_ viewModel: ResourceErrorViewModel)
}
```

### Shared ViewModels

**ResourceLoadingViewModel:**
```swift
public struct ResourceLoadingViewModel {
    public let isLoading: Bool
}
```

**ResourceErrorViewModel:**
```swift
public struct ResourceErrorViewModel {
    public let message: String?

    static var noError: ResourceErrorViewModel {
        return ResourceErrorViewModel(message: nil)
    }

    static func error(message: String) -> ResourceErrorViewModel {
        return ResourceErrorViewModel(message: message)
    }
}
```

---

## Video Presentation

### VideoPlayerPresenter

**File:** `StreamingCore/StreamingCore/Video Presentation/VideoPlayerPresenter.swift`

Maps Video domain model to VideoPlayerViewModel and provides time formatting.

```swift
public final class VideoPlayerPresenter {
    public static var title: String {
        NSLocalizedString(
            "VIDEO_PLAYER_VIEW_TITLE",
            tableName: "VideoPlayer",
            bundle: Bundle(for: VideoPlayerPresenter.self),
            comment: "Title for the video player view")
    }

    public static func map(_ video: Video) -> VideoPlayerViewModel {
        VideoPlayerViewModel(
            title: video.title,
            videoURL: video.url
        )
    }

    public static func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }

        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
```

### VideoPlayerViewModel

**File:** `StreamingCore/StreamingCore/Video Presentation/VideoPlayerViewModel.swift`

```swift
public struct VideoPlayerViewModel {
    public let title: String
    public let videoURL: URL

    public init(title: String, videoURL: URL) {
        self.title = title
        self.videoURL = videoURL
    }
}
```

### VideoImagePresenter

**File:** `StreamingCore/StreamingCore/Video Presentation/VideoImagePresenter.swift`

Maps Video to VideoImageViewModel for cell display.

```swift
public final class VideoImagePresenter {
    public static func map(_ video: Video) -> VideoImageViewModel {
        VideoImageViewModel(
            title: video.title,
            description: video.description)
    }
}
```

### VideoImageViewModel

**File:** `StreamingCore/StreamingCore/Video Presentation/VideoImageViewModel.swift`

```swift
public struct VideoImageViewModel {
    public let title: String
    public let description: String?

    public var hasDescription: Bool {
        return description != nil
    }
}
```

### VideosPresenter

**File:** `StreamingCore/StreamingCore/Video Presentation/VideosPresenter.swift`

Provides localized title for videos list.

```swift
public final class VideosPresenter {
    public static var title: String {
        NSLocalizedString("VIDEO_VIEW_TITLE",
            tableName: "Video",
            bundle: Bundle(for: VideosPresenter.self),
            comment: "Title for the video view")
    }
}
```

### VideoViewModel

**File:** `StreamingCore/StreamingCore/Video Presentation/VideoViewModel.swift`

```swift
public struct VideoViewModel {
    public let title: String?
    public let description: String?

    public init(title: String?, description: String?) {
        self.title = title
        self.description = description
    }

    public var hasTitle: Bool {
        return title != nil
    }
}
```

---

## Comments Presentation

### VideoCommentsPresenter

**File:** `StreamingCore/StreamingCore/Video Comments Presentation/VideoCommentsPresenter.swift`

Provides the localized comments title and maps `VideoComment` domain models to display view models, converting `createdAt` into a relative date string via `RelativeDateTimeFormatter`. Consumed by the iOS `VideoCommentsUIComposer` (comments are an iOS-only surface).

```swift
public struct VideoCommentsViewModel: Sendable {
    public let comments: [VideoCommentViewModel]
}

public struct VideoCommentViewModel: Hashable, Sendable {
    public let message: String
    public let date: String
    public let username: String

    public init(message: String, date: String, username: String) {
        self.message = message
        self.date = date
        self.username = username
    }
}

public final class VideoCommentsPresenter {
    public static var title: String {
        NSLocalizedString(
            "VIDEO_COMMENTS_VIEW_TITLE",
            tableName: "VideoComments",
            bundle: Bundle(for: VideoCommentsPresenter.self),
            comment: "Title for the video comments view")
    }

    public static func map(
        _ comments: [VideoComment],
        currentDate: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> VideoCommentsViewModel {
        let formatter = RelativeDateTimeFormatter()
        formatter.calendar = calendar
        formatter.locale = locale

        return VideoCommentsViewModel(
            comments: comments.map { comment in
                VideoCommentViewModel(
                    message: comment.message,
                    date: formatter.localizedString(for: comment.createdAt, relativeTo: currentDate),
                    username: comment.username)
            })
    }
}
```

The injectable `currentDate`, `calendar`, and `locale` parameters keep the relative-date formatting deterministic and unit-testable. See [Apple TV](features/APPLE-TV.md) for the tvOS comments surface.

---

## Data Flow

```mermaid
flowchart TB
    A[1. View triggers load] --> B["2. Presenter.didStartLoading()"]
    B --> B1["errorView.display(.noError)"]
    B --> B2["loadingView.display(isLoading: true)"]
    B --> C[3. Use case loads resource]
    C -->|Success| D["Presenter.didFinishLoading(with: resource)"]
    C -->|Failure| E["Presenter.didFinishLoading(with: error)"]
    D --> D1["mapper(resource) &rarr; ViewModel"]
    D --> D2["resourceView.display(viewModel)"]
    D --> D3["loadingView.display(isLoading: false)"]
    E --> E1["errorView.display(.error(message))"]
    E --> E2["loadingView.display(isLoading: false)"]

    classDef neutral fill:#fef7e0,stroke:#f9ab00,color:#202124;
    classDef core fill:#e6f4ea,stroke:#34a853,color:#202124;
    classDef impure fill:#fce8e6,stroke:#ea4335,color:#202124;
    class A,B,C,B1,B2 neutral;
    class D,D1,D2,D3 core;
    class E,E1,E2 impure;
```

---

## Usage Examples

### Using LoadResourcePresenter with Videos

```swift
typealias VideosPresentationAdapter = AsyncLoadResourcePresentationAdapter<Paginated<Video>, VideosViewAdapter>

let presentationAdapter = VideosPresentationAdapter(loader: videoLoader)

let videosController = makeVideosViewController()
videosController.onRefresh = presentationAdapter.loadResource

presentationAdapter.presenter = LoadResourcePresenter(
    resourceView: VideosViewAdapter(
        controller: videosController,
        imageLoader: imageLoader,
        selection: selection),
    loadingView: WeakRefVirtualProxy(videosController),
    errorView: WeakRefVirtualProxy(videosController))
```

### Using VideoPlayerPresenter

```swift
let video: Video = ...
let viewModel = VideoPlayerPresenter.map(video)

// Format playback time
let currentTime: TimeInterval = 125  // 2:05
let formattedTime = VideoPlayerPresenter.formatTime(currentTime)
// Result: "2:05"

let longVideo: TimeInterval = 3725  // 1:02:05
let formattedLongTime = VideoPlayerPresenter.formatTime(longVideo)
// Result: "1:02:05"
```

### Using VideoImagePresenter for Cells

```swift
func cellController(for video: Video) -> CellController {
    let viewModel = VideoImagePresenter.map(video)
    // Use viewModel to configure cell
}
```

---

## Testing

### LoadResourcePresenter Tests

```swift
func test_didStartLoading_displaysLoadingAndNoError() {
    let (sut, view) = makeSUT()

    sut.didStartLoading()

    XCTAssertEqual(view.messages, [
        .display(errorMessage: nil),
        .display(isLoading: true)
    ])
}

func test_didFinishLoadingWithResource_displaysResourceAndStopsLoading() {
    let (sut, view) = makeSUT(mapper: { "\($0) view model" })

    sut.didFinishLoading(with: "resource")

    XCTAssertEqual(view.messages, [
        .display(resourceViewModel: "resource view model"),
        .display(isLoading: false)
    ])
}

func test_didFinishLoadingWithError_displaysErrorAndStopsLoading() {
    let (sut, view) = makeSUT()

    sut.didFinishLoading(with: anyNSError())

    XCTAssertEqual(view.messages, [
        .display(errorMessage: localized("GENERIC_CONNECTION_ERROR")),
        .display(isLoading: false)
    ])
}
```

### VideoPlayerPresenter Tests

```swift
func test_map_createsViewModelFromVideo() {
    let video = makeVideo(title: "Test", url: anyURL())

    let viewModel = VideoPlayerPresenter.map(video)

    XCTAssertEqual(viewModel.title, "Test")
    XCTAssertEqual(viewModel.videoURL, video.url)
}

func test_formatTime_formatsSecondsCorrectly() {
    XCTAssertEqual(VideoPlayerPresenter.formatTime(0), "0:00")
    XCTAssertEqual(VideoPlayerPresenter.formatTime(5), "0:05")
    XCTAssertEqual(VideoPlayerPresenter.formatTime(65), "1:05")
    XCTAssertEqual(VideoPlayerPresenter.formatTime(3665), "1:01:05")
}

func test_formatTime_handlesInvalidInput() {
    XCTAssertEqual(VideoPlayerPresenter.formatTime(.nan), "0:00")
    XCTAssertEqual(VideoPlayerPresenter.formatTime(.infinity), "0:00")
}
```

---

## Design Patterns

### Mapper Pattern

Presenters use static `map` functions to transform domain models:

```swift
// Domain → ViewModel transformation
public static func map(_ video: Video) -> VideoPlayerViewModel
```

Benefits:
- Pure functions, easy to test
- No state, no side effects
- Clear input/output contract

### Generic Presenter Pattern

`LoadResourcePresenter<Resource, View>` handles any resource type:

```swift
// Videos
LoadResourcePresenter<Paginated<Video>, VideosViewAdapter>

// Comments
LoadResourcePresenter<[VideoComment], CommentsViewAdapter>

// Image Data
LoadResourcePresenter<Data, ImageViewAdapter>
```

### View Protocol Pattern

Views conform to specific protocols:

```swift
class ListViewController: UITableViewController, ResourceLoadingView, ResourceErrorView {
    func display(_ viewModel: ResourceLoadingViewModel) {
        refreshControl?.update(viewModel.isLoading)
    }

    func display(_ viewModel: ResourceErrorViewModel) {
        errorView?.message = viewModel.message
    }
}
```

---

## Architecture Benefits

### Separation of Concerns

```
Presenter                          ViewModel                     View
─────────                          ─────────                     ────
• Transforms data                  • Holds display data          • Renders UI
• Formats strings                  • No logic                    • Binds to ViewModel
• Handles localization             • Immutable                   • User interaction
• Contains presentation logic      • Value type                  • UIKit/SwiftUI
```

### Testability

- ViewModels are simple structs - easy to construct in tests
- Presenters have no UI dependencies - pure unit tests
- View protocols enable test doubles

### Platform Independence

```mermaid
flowchart TB
    subgraph Core["StreamingCore (Platform-Agnostic)"]
        P["VideoPlayerPresenter &rarr; used in iOS, tvOS<br/>VideoPlayerViewModel &rarr; same data structure anywhere"]
    end
    P --> iOS["iOS View<br/><i>(UIKit)</i>"]
    P --> tvOS["tvOS View<br/><i>(UIKit)</i>"]
    P -.-> macOS["macOS<br/><i>(test/CI destination only)</i>"]

    classDef core fill:#e6f4ea,stroke:#34a853,color:#202124;
    classDef app fill:#e8f0fe,stroke:#4285f4,color:#202124;
    classDef test fill:#f1f3f4,stroke:#9aa0a6,color:#202124;
    class P core;
    class iOS,tvOS app;
    class macOS test;
```

The two shipping UI surfaces are **iOS** (`Tattva`) and **tvOS** (`TattvaTV`), both UIKit. There is no macOS AppKit app; macOS appears only as a unit-test/CI destination (`CI_macOS` scheme) that exercises `StreamingCore` logic under ThreadSanitizer.

---

## Related Documentation

- [Composition Root](COMPOSITION-ROOT.md) - Wiring presenters to views
- [Cell Controllers](CELL-CONTROLLERS.md) - Cell-level presentation
- [SOLID Principles](SOLID.md) - Single Responsibility in presentation
- [Design Patterns](DESIGN-PATTERNS.md) - MVP pattern details
