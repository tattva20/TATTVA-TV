# TATTVA TV

<p align="center">
  <img src="docs/images/brand/tattva-tv-hero.jpg" alt="TATTVA TV — Meaningful stories. Beautifully streamed." width="760">
</p>

<p align="center">
  <a href="https://github.com/tattva20/TATTVA-TV/actions/workflows/ci.yml">
    <img src="https://github.com/tattva20/TATTVA-TV/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
  <img src="https://img.shields.io/badge/Platform-iOS%2026.1%2B%20%7C%20tvOS%2026.0%2B-blue.svg" alt="Platform: iOS 26.1+ | tvOS 26.0+">
  <img src="https://img.shields.io/badge/Swift-6-orange.svg" alt="Swift 6">
  <img src="https://img.shields.io/badge/Xcode-26.5-blue.svg" alt="Xcode 26.5">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
</p>

<p align="center">
  A portfolio-grade <strong>iOS and tvOS</strong> video streaming application built with <strong>Test-Driven Development (TDD)</strong>, <strong>SOLID principles</strong>, and <strong>Clean Architecture</strong>.
</p>

---

## Documentation

For a deeper understanding of the philosophies, patterns, and principles behind this codebase, explore our detailed documentation:

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | Clean Architecture layers, boundaries, and data flow |
| [Dependency Rejection](docs/DEPENDENCY-REJECTION.md) | Pure functions and the "Impure → Pure → Impure" sandwich |
| [TDD](docs/TDD.md) | Test-Driven Development practices and testing patterns |
| [SOLID](docs/SOLID.md) | SOLID principles with concrete code examples |
| [State Machines](docs/STATE-MACHINES.md) | Pure state machine design for video playback |
| [Design Patterns](docs/DESIGN-PATTERNS.md) | Decorator, Composite, Adapter, Strategy patterns |
| [Reactive Programming](docs/REACTIVE-PROGRAMMING.md) | Combine framework patterns and best practices |
| [Performance](docs/PERFORMANCE.md) | Bitrate adaptation, preloading, and memory management |

### Feature Documentation

Detailed documentation for each streaming feature:

| Feature | Description |
|---------|-------------|
| [Apple TV (tvOS)](docs/features/APPLE-TV.md) | Native TATTVA TV app reusing the full core: focus feed, native player, comments |
| [Video Feed](docs/features/VIDEO-FEED.md) | Paginated video list with infinite scroll and caching |
| [Video Playback](docs/features/VIDEO-PLAYBACK.md) | Full-featured player with state machine and controls |
| [Video Comments](docs/features/VIDEO-COMMENTS.md) | Threaded comments with relative timestamps |
| [Picture-in-Picture](docs/features/PICTURE-IN-PICTURE.md) | Floating video window for multitasking |
| [Thumbnail Loading](docs/features/THUMBNAIL-LOADING.md) | Lazy image loading with shimmer and caching |
| [Offline Support](docs/features/OFFLINE-SUPPORT.md) | CoreData caching and fallback strategies |
| [Analytics](docs/features/ANALYTICS.md) | Playback tracking and engagement metrics |
| [Logging](docs/features/LOGGING.md) | Structured logging with correlation IDs |
| [Buffer Management](docs/features/BUFFER-MANAGEMENT.md) | Adaptive buffering based on network and memory |
| [Memory Management](docs/features/MEMORY-MANAGEMENT.md) | Pressure monitoring and resource cleanup |
| [Network Quality](docs/features/NETWORK-QUALITY.md) | Real-time network monitoring and bandwidth estimation |

### Advanced Streaming Features

Core streaming infrastructure for high-quality video playback:

| Feature | Description |
|---------|-------------|
| [Player State Machine](docs/features/PLAYER-STATE-MACHINE.md) | Explicit, exhaustively tested state transitions |
| [Adaptive Bitrate](docs/features/ADAPTIVE-BITRATE.md) | Quality selection based on network and buffer health |
| [Video Preloading](docs/features/VIDEO-PRELOADING.md) | Predictive loading for seamless transitions |
| [Rebuffering Detection](docs/features/REBUFFERING-DETECTION.md) | Stall monitoring and ratio tracking |
| [Startup Performance](docs/features/STARTUP-PERFORMANCE.md) | Time-to-First-Frame (TTFF) measurement |
| [Performance Alerts](docs/features/PERFORMANCE-ALERTS.md) | Threshold monitoring and severity levels |
| [Audio Session](docs/features/AUDIO-SESSION.md) | Interruption handling and category configuration |
| [AVPlayer Integration](docs/features/AVPLAYER-INTEGRATION.md) | Platform adapter bridging AVPlayer to domain |

### Infrastructure Documentation

Detailed documentation for infrastructure components and patterns:

| Document | Description |
|----------|-------------|
| [HTTP Client](docs/HTTP-CLIENT.md) | HTTPClient protocol, URLSession implementation, mappers |
| [Pagination](docs/PAGINATION.md) | Cursor-based (keyset) paging with `after_id`, load-more, and end-of-feed signalling |
| [Caching Infrastructure](docs/CACHING-INFRASTRUCTURE.md) | VideoStore, CoreData, InMemory implementations |
| [Composition Root](docs/COMPOSITION-ROOT.md) | SceneDelegate wiring, Composers, dependency graph |
| [Presenters & ViewModels](docs/PRESENTERS-VIEWMODELS.md) | LoadResourcePresenter, mappers, presentation layer |
| [Cell Controllers](docs/CELL-CONTROLLERS.md) | CellController pattern, diffable data source integration |
| [Controls Visibility](docs/CONTROLS-VISIBILITY.md) | Auto-hide controls with timer management |
| [Bandwidth Estimation](docs/BANDWIDTH-ESTIMATION.md) | Network measurement, quality monitoring, bitrate recommendations |
| [Testing Infrastructure](docs/TESTING-INFRASTRUCTURE.md) | Spy patterns, memory leak tracking, spec assertions |
| [Branding](docs/BRANDING.md) | TATTVA TV brand assets — layered tvOS App Icon + Top Shelf pipeline |

---

## Overview

Tattva demonstrates professional iOS and tvOS development practices with a modular, testable architecture. Both apps — the iOS app (`Tattva`) and the Apple TV app (`TattvaTV`, branded **TATTVA TV**) — sit on top of the same shared `StreamingCore` and `StreamingCorePlayback` frameworks.

### Key Highlights

- **Test-Driven** - Features developed test-first, backed by an extensive automated test suite
- **Clean Architecture** - Clear separation of concerns across modules
- **SOLID Principles** - Maintainable, extensible codebase
- **Comprehensive Testing** - Unit, Integration, and End-to-End tests
- **CI/CD Ready** - GitHub Actions with ThreadSanitizer

---

## Features

### Video Feed
- Paginated video list with infinite scroll
- Pull-to-refresh functionality
- Lazy image loading with caching
- Error handling with retry mechanism

### Video Player
- Full-featured AVPlayer implementation
- Play/Pause with elegant UI
- Seek forward/backward (10 seconds)
- Progress bar with time display
- Volume control with mute toggle
- Playback speed (0.5x, 1x, 1.25x, 1.5x, 2x)
- Fullscreen mode with orientation support
- Picture-in-Picture (PiP) support
- Auto-hiding controls overlay

### Video Comments
- Threaded comment display
- Pull-to-refresh for latest comments
- Relative timestamp formatting

### Offline Support
- CoreData persistence for video metadata
- Image caching for offline viewing
- Cache-first loading strategy with remote fallback

### Apple TV (tvOS) — TATTVA TV
- Native 10-foot playback via `AVPlayerViewController`
- Focus-engine video feed (`UICollectionView` + diffable data source) with load-more pagination
- Comments beside the player, with loading / empty / error states
- Reuses the entire `StreamingCore` + `StreamingCorePlayback` stack — tvOS adds only its UI
- Purpose-built brand assets: layered App Icon + Top Shelf

<p align="center">
  <img src="docs/images/brand/top-shelf.jpg" alt="TATTVA TV Top Shelf art" width="720">
</p>

---

## Architecture

Tattva follows a **modular Clean Architecture** with strict layer boundaries:

```mermaid
flowchart TB
    iOSApp["Tattva<br/><i>iOS app · composition root</i>"]
    tvApp["TattvaTV<br/><i>tvOS app · composition root</i>"]
    iOS["StreamingCoreiOS<br/><i>UIKit UI</i>"]
    Playback["StreamingCorePlayback<br/><i>AVFoundation · reused playback stack</i>"]
    Core["StreamingCore<br/><i>domain · use cases · presenters · protocols</i><br/>🚫 No UIKit / AVKit"]

    iOSApp --> iOS
    iOSApp --> Playback
    tvApp --> Playback
    iOS --> Core
    Playback --> Core
    iOSApp --> Core
    tvApp --> Core

    classDef app fill:#e8f0fe,stroke:#4285f4,color:#202124;
    classDef ios fill:#e6f4ea,stroke:#34a853,color:#202124;
    classDef pb fill:#f3e8fd,stroke:#a142f4,color:#202124;
    classDef core fill:#fef7e0,stroke:#f9ab00,color:#202124;
    class iOSApp,tvApp app
    class iOS ios
    class Playback pb
    class Core core
```

### Module Structure

```
Tattva.xcworkspace — dependencies point inward to StreamingCore

apps · composition roots
├── Tattva      iOS app    → Core · CoreiOS · CorePlayback   (custom UIKit player)
└── TattvaTV    tvOS app   → Core · CorePlayback             (native AVPlayerViewController)

frameworks
├── StreamingCoreiOS       UIKit          → Core   iOS feed / player / comments UI
├── StreamingCorePlayback  AVFoundation   → Core   AVPlayerVideoPlayer · logging/analytics decorators ·
│                                                  StatefulVideoPlayer · PlaybackCoordinator · bandwidth/perf
└── StreamingCore          Foundation · Combine · CoreData   domain · use cases · presenters · protocols
                                                             (🚫 no UIKit / AVKit)

tests
└── StreamingCoreTests · StreamingCoreiOSTests · StreamingCoreAPIEndToEndTests ·
    StreamingCoreCacheIntegrationTests · TattvaTests · TattvaTVTests

CI · .github/workflows/ci.yml
└── build-ios · build-macos · build-tvos
```

### Design Patterns

| Pattern | Usage |
|---------|-------|
| **Composition Root** | All dependencies wired in `SceneDelegate` |
| **Decorator** | `VideoLoaderCacheDecorator` adds caching |
| **Composite** | `VideoLoaderComposite` for fallback loading |
| **Adapter** | Connects domain to presentation layer |
| **Factory** | Creates complex object graphs |
| **Strategy** | Interchangeable loading strategies |

---

## Design Philosophy

### Why TDD?

Test-Driven Development is not optional in this codebase:

- **Tests document behavior** - Tests describe what the code should do, not how
- **Confidence to refactor** - Comprehensive tests enable fearless changes
- **Forces decoupled design** - Hard to test = hard to maintain
- **Catches regressions immediately** - Red tests show exactly what broke

### Why Clean Architecture?

Clean Architecture keeps the codebase maintainable as it grows:

- **Business logic survives UI changes** - Core doesn't know about UIKit
- **Platform-agnostic core enables reuse** - Same core for iOS, tvOS, macOS
- **Clear boundaries prevent coupling** - Dependencies flow inward only
- **Easy to test in isolation** - No framework dependencies in tests

### Why SOLID?

SOLID principles make code that scales:

- **Single Responsibility** - Each class is easy to understand and test
- **Open/Closed** - Add features without modifying existing code
- **Liskov Substitution** - Swap implementations freely (mocks, stubs, real)
- **Interface Segregation** - No class forced to implement unused methods
- **Dependency Inversion** - High-level modules independent of low-level details

---

## SOLID Principles in Practice

### Single Responsibility (S)

Each class has ONE reason to change:

```swift
// Good - Separate responsibilities
RemoteVideoLoader    // Only fetches from network
LocalVideoLoader     // Only fetches from cache
VideoLoaderCacheDecorator  // Only handles caching logic
```

### Open/Closed (O)

Extend behavior without modifying existing code using the Decorator pattern:

```swift
// Adding caching without changing RemoteVideoLoader
let cachedLoader = VideoLoaderCacheDecorator(
    decoratee: remoteLoader,
    cache: localCache
)
```

### Liskov Substitution (L)

Any `VideoLoader` implementation can replace another:

```swift
protocol VideoLoader {
    func load() async throws -> [Video]
}

// All these can be used interchangeably:
let loader: VideoLoader = RemoteVideoLoader(...)     // Production
let loader: VideoLoader = LocalVideoLoader(...)      // Offline
let loader: VideoLoader = VideoLoaderCacheDecorator(...) // Cached
let loader: VideoLoader = VideoLoaderSpy()           // Testing
```

### Interface Segregation (I)

Small, focused protocols instead of large ones:

```swift
// Good - Clients adopt only what they need
protocol VideoLoader { ... }
protocol VideoCache { ... }
protocol VideoImageDataLoader { ... }

// Bad - One giant protocol forces unused implementations
protocol VideoService {
    func load() async throws -> [Video]
    func cache(_ videos: [Video]) async throws
    func loadImage(for video: Video) async throws -> Data
    func validate(_ video: Video) -> Bool
    // ... 20 more methods
}
```

### Dependency Inversion (D)

High-level modules depend on abstractions, not concretions:

```swift
// StreamingCore defines protocols (abstractions)
public protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

// StreamingCore provides the URLSession implementation (concretion)
public final class URLSessionHTTPClient: HTTPClient { ... }

// Business logic never knows about URLSession
```

---

## Getting Started

### Requirements

- **Xcode 26.5+**
- **iOS 26.1+** · **tvOS 26.0+**
- **Swift 6 toolchain** (Swift 6 language mode)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/tattva20/TATTVA-TV.git
   cd TATTVA-TV
   ```

2. **Open the workspace**
   ```bash
   open Tattva.xcworkspace
   ```

3. **Select scheme and run**
   - Choose `Tattva` (iOS) or `TattvaTV` (Apple TV)
   - Select a simulator or device
   - Press `Cmd + R` to run

### Running Tests

```bash
# Run all tests
xcodebuild test \
  -workspace Tattva.xcworkspace \
  -scheme Tattva \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Run with ThreadSanitizer (CI mode)
xcodebuild clean build test \
  -workspace Tattva.xcworkspace \
  -scheme "CI_iOS" \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -enableThreadSanitizer YES
```

---

## Testing Strategy

### Test Pyramid

<p align="center">
  <img src="docs/images/test-pyramid.svg" alt="Test pyramid: ~1,039 unit tests (isolated components), ~113 integration (composed systems), ~2 end-to-end (real API)" width="520">
</p>

### Test Categories

| Category | Location | Description |
|----------|----------|-------------|
| **Unit** | `StreamingCoreTests/` | Test single units with mocks |
| **iOS Unit** | `StreamingCoreiOSTests/` | Test UI components |
| **Integration** | `TattvaTests/` | Test composed systems |
| **API E2E** | `StreamingCoreAPIEndToEndTests/` | Test against real API |
| **Cache Integration** | `StreamingCoreCacheIntegrationTests/` | Test real CoreData |

### Test Coverage Focus

- **Presenters** - Business logic and state management
- **Use Cases** - Loading, caching, validation flows
- **Mappers** - JSON parsing and data transformation
- **View Controllers** - User interaction handling
- **Composers** - Dependency wiring

---

## CI/CD

### GitHub Actions Workflow

A single workflow (`.github/workflows/ci.yml`) runs three jobs on every push and PR to `main`:

| Job | Trigger | Description |
|----------|---------|-------------|
| **build-ios** | Push/PR to main | Full test suite on the iOS Simulator (scheme `CI_iOS`, iPhone 17 / iOS 26.5) |
| **build-macos** | Push/PR to main | Platform-agnostic Core tests, no simulator, ThreadSanitizer on (scheme `CI_macOS`) |
| **build-tvos** | Push/PR to main | Full test suite on the Apple TV Simulator (scheme `CI_tvOS`, Apple TV 4K 3rd gen) |

### CI Features

- **ThreadSanitizer** - Detects data races and threading issues (macOS job)
- **Three-platform jobs** - iOS Simulator, macOS, and tvOS Simulator run concurrently
- **Multiple Xcode Versions** - Fallback Xcode selection
- **Test result bundles** - `.xcresult` uploaded as artifacts on failure

### Branch Protection Rules

The `main` branch is protected with the following rules:

| Rule | Setting | Description |
|------|---------|-------------|
| **Require PR** | Enabled | No direct pushes to main |
| **Required Approvals** | 1 | At least one reviewer must approve |
| **Dismiss Stale Reviews** | Enabled | New commits invalidate existing approvals |
| **Required Status Checks** | `build-ios`, `build-macos` | CI must pass before merge |
| **Up-to-date Branch** | Required | Branch must be current with main |
| **Conversation Resolution** | Required | All review comments must be resolved |
| **Force Push** | Allowed (owner only) | Repository owner can force push |
| **Enforce for Admins** | Disabled | Owner can bypass rules when needed |

### Setting Up Branch Protection

Configure branch protection manually at:
`https://github.com/tattva20/TATTVA-TV/settings/branches`

---

## API

### Backend

The app connects to a custom API deployed on Vercel, base URL `https://streaming-videos-api.vercel.app`:

| Endpoint | Description |
|----------|-------------|
| `GET /v1/videos?limit=10&after_id={id}` | Paginated video list (keyset cursor) |
| `GET /v1/videos/{id}/comments` | Video comments |

### Sample Response

```json
{
  "videos": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "Big Buck Bunny",
      "description": "A large and lovable rabbit deals with three tiny bullies.",
      "duration": 596,
      "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      "thumbnail_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Big_buck_bunny_poster_big.jpg/330px-Big_buck_bunny_poster_big.jpg"
    }
  ]
}
```

---

## Development

### TDD Workflow

```
1. RED    → Write a failing test
2. GREEN  → Write minimum code to pass
3. REFACTOR → Clean up while tests pass
```

### Adding New Features

1. **Define Protocol** in `StreamingCore`
2. **Write Tests** for the protocol
3. **Implement** the minimum code
4. **Create UI** in `StreamingCoreiOS`
5. **Wire Up** in composition root
6. **Add Integration Tests**

### Code Style

- Swift standard naming conventions
- Protocol-oriented design
- Dependency injection over singletons
- Value types where appropriate
- Clear, descriptive naming

---

## Project History

This project was developed following TDD principles from the ground up:

1. **Foundation** - Core video loading with cache
2. **Remote API** - HTTPClient and video mapping
3. **Persistence** - CoreData integration
4. **UI Layer** - Videos list with pagination
5. **Video Player** - Full-featured playback
6. **Comments** - Video comments feature
7. **PiP** - Picture-in-Picture support
8. **CI/CD** - GitHub Actions automation

---

## Contributing

### Prerequisites

Before contributing, ensure you:

1. Read this entire README, especially [Design Philosophy](#design-philosophy) and [SOLID Principles](#solid-principles-in-practice)
2. Understand TDD, SOLID, and Clean Architecture
3. Have Xcode 16+ installed
4. Can run all tests successfully

### Contribution Workflow

#### Step 1: Create Feature Branch

```bash
git checkout -b feature/your-feature-name
```

#### Step 2: Write Failing Test FIRST (Red)

```swift
// In appropriate test target
func test_newFeature_deliversExpectedBehavior() {
    let sut = makeSUT()

    let result = sut.performAction()

    XCTAssertEqual(result, expectedValue)
}
```

#### Step 3: Implement Minimum Code (Green)

Write ONLY enough code to make the test pass. No extra features, no premature optimization.

#### Step 4: Refactor (Keep Tests Green)

Clean up while ensuring tests still pass. Extract protocols if needed. Remove duplication.

#### Step 5: Add Integration Tests

If the feature involves composition, write tests in `TattvaTests/`.

#### Step 6: Verify All Tests Pass

```bash
xcodebuild test -scheme CI_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

#### Step 7: Submit PR

Follow the [PR Requirements](#pull-request-requirements) below.

### Code Style

- Swift standard naming conventions
- Protocol-oriented design
- Dependency injection over singletons
- Value types where appropriate
- Clear, descriptive naming
- No force unwraps unless absolutely necessary

---

## Pull Request Requirements

### Before Submitting

#### Code Quality Checklist

- [ ] All existing tests pass
- [ ] New code has corresponding tests
- [ ] No commented-out code
- [ ] No print statements or debug logs
- [ ] Clear, descriptive naming
- [ ] No force unwraps unless justified

#### Architecture Compliance

- [ ] StreamingCore has NO UIKit imports
- [ ] New protocols in Core, implementations in iOS/App
- [ ] Dependencies injected, not created internally
- [ ] No singletons or global state

#### Testing Standards

- [ ] Tests follow Given-When-Then structure
- [ ] Memory leak tracking included (`trackForMemoryLeaks`)
- [ ] UI tests have `RunLoop.current.run(until: Date())` in tearDown
- [ ] Async code has proper `await Task.yield()` patterns
- [ ] Test doubles use correct pattern (see [Testing Patterns](#testing-patterns))

#### TDD Evidence

- [ ] Can demonstrate test was written before implementation
- [ ] Tests describe behavior, not implementation details
- [ ] No tests that simply test framework code

### PR Description Template

```markdown
## Summary
[1-2 sentences describing the change]

## Motivation
[Why is this change needed?]

## Changes
- [Bullet point changes]

## Test Plan
- [How was this tested?]
- [What edge cases were considered?]

## Screenshots (if UI change)
[Before/After screenshots]
```

---

## Adding New Features

### Feature in StreamingCore (Business Logic)

#### 1. Define the Protocol

```swift
// StreamingCore/NewFeature/NewFeatureLoader.swift
public protocol NewFeatureLoader {
    func load() async throws -> [NewFeature]
}
```

#### 2. Write Tests for Expected Behavior

```swift
// StreamingCoreTests/NewFeature/RemoteNewFeatureLoaderTests.swift
func test_load_deliversItemsOnSuccess() async throws {
    let (sut, client) = makeSUT()
    let expectedItems = [makeItem(), makeItem()]

    client.complete(with: expectedItems)

    let result = try await sut.load()
    XCTAssertEqual(result, expectedItems)
}
```

#### 3. Implement the Loader

```swift
// StreamingCore/NewFeature/RemoteNewFeatureLoader.swift
public final class RemoteNewFeatureLoader: NewFeatureLoader {
    private let client: HTTPClient
    private let url: URL

    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load() async throws -> [NewFeature] {
        let (data, response) = try await client.get(from: url)
        return try NewFeatureMapper.map(data, from: response)
    }
}
```

#### 4. Add Caching (if needed)

Use the Decorator pattern:

```swift
public final class NewFeatureLoaderCacheDecorator: NewFeatureLoader {
    private let decoratee: NewFeatureLoader
    private let cache: NewFeatureCache

    public init(decoratee: NewFeatureLoader, cache: NewFeatureCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    public func load() async throws -> [NewFeature] {
        let items = try await decoratee.load()
        try await cache.save(items)
        return items
    }
}
```

### Feature in StreamingCoreiOS (UI)

#### 1. Create View Controller

```swift
// StreamingCoreiOS/NewFeature UI/NewFeatureViewController.swift
@MainActor
public final class NewFeatureViewController: UIViewController {
    // UI implementation
}
```

#### 2. Create Cell Controller (if list-based)

Follow the CellController pattern from existing implementations.

#### 3. Write UI Tests

```swift
// StreamingCoreiOSTests/NewFeature UI/NewFeatureViewControllerTests.swift
@MainActor
final class NewFeatureViewControllerTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        RunLoop.current.run(until: Date())  // Critical for UIKit cleanup
    }
}
```

### Wiring in Composition Root

#### 1. Create Composer

```swift
// Tattva/NewFeatureUIComposer.swift
enum NewFeatureUIComposer {
    static func compose(
        loader: NewFeatureLoader
    ) -> NewFeatureViewController {
        let viewModel = NewFeatureViewModel()
        let controller = NewFeatureViewController(viewModel: viewModel)
        // Wire dependencies
        return controller
    }
}
```

#### 2. Add to SceneDelegate

Wire the new feature into the navigation flow.

---

## Code Review Criteria

### Automatic Rejection (Architecture Violations)

- UIKit/AppKit imports in StreamingCore
- Direct instantiation instead of injection
- Circular dependencies between modules
- Business logic in UI layer

### Requires Justification (TDD Violations)

- Code without corresponding tests
- Tests that test implementation details
- Tests that rely on timing/delays
- Skipped or disabled tests

### Requires Discussion (SOLID Violations)

- Classes with multiple responsibilities
- Concrete dependencies instead of protocols
- Large interfaces that force unused methods
- High-level modules depending on low-level details

### Must Fix (Code Quality Issues)

- Force unwraps without safety
- Retain cycles (missing `[weak self]`)
- Memory leaks in tests
- Inconsistent naming conventions
- Missing error handling

### Suggestions (Style Issues)

- Long methods (>20 lines)
- Deep nesting (>3 levels)
- Magic numbers without constants
- Missing documentation on public API

---

## Testing Patterns

### Memory Leak Detection

Always include in test helpers:

```swift
private func makeSUT(
    file: StaticString = #filePath,
    line: UInt = #line
) -> SUT {
    let sut = SUT()
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
}
```

### UI Test Cleanup

**Critical:** Prevent malloc errors with RunLoop processing:

```swift
@MainActor
final class MyUITests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        RunLoop.current.run(until: Date())
    }
}
```

### Async Test Pattern

For code that spawns Tasks:

```swift
func test_action_triggersAsyncBehavior() async {
    let sut = makeSUT()

    sut.performAction()
    await Task.yield()  // Let spawned Tasks run

    // Assert on results
}
```

### Test Double Selection

| Scenario | Pattern |
|----------|---------|
| Synchronous spy in UI test | `@MainActor final class Spy` |
| Async operations | `actor Spy` |
| Cross-actor shared state | `@unchecked Sendable + NSLock` |
| Simple stub | `struct Stub` |

Example with NSLock for cross-actor access:

```swift
final class ResourceCleanerSpy: ResourceCleaner, @unchecked Sendable {
    private let lock = NSLock()
    private var _cleanupCallCount = 0

    var cleanupCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _cleanupCallCount
    }

    func cleanup() {
        lock.lock()
        _cleanupCallCount += 1
        lock.unlock()
    }
}
```

---

## Lessons Learned & Pitfalls to Avoid

This section documents solutions to persistent issues discovered during development.

### 1. Swift 6 @MainActor Deallocation Crash

**Problem:** malloc crash at fixed address during @MainActor class deallocation.

**Error:**
```
malloc: *** error for object 0x262c5a6f0: pointer being freed was not allocated
```

**Root Cause:** A known Swift runtime bug in deinit isolation — a `@MainActor`-isolated `deinit` can run on the wrong executor and crash inside `swift_task_deinitOnExecutorImpl` (see [swiftlang/swift#87316](https://github.com/swiftlang/swift/issues/87316)).

**Solution:**
1. Set `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` in build settings
2. Add explicit `@MainActor` to classes that need main thread access
3. Add `RunLoop.current.run(until: Date())` in test tearDown

**DO NOT:** Set `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (causes crashes)

### 2. UIKit Test Cleanup

**Problem:** Tests crash with malloc errors when running in sequence.

**Root Cause:** UIKit views and constraints deallocate asynchronously.

**Solution:**
```swift
@MainActor
final class MyUITests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        RunLoop.current.run(until: Date())
    }
}
```

### 3. Mixing async/await and Combine

**Problem:** Owning the same state in both Combine and async/await — or bridging them bidirectionally — causes ownership ambiguity and race conditions.

**Solution:** Own each boundary in a single model. A *one-directional, temporary* bridge during a migration is fine — when this codebase moved its feed and comments loaders from Combine to async/await, the interim `HTTPClient`→`Future` bridge was deleted once the migration landed. What to avoid is *permanent bidirectional* mixing, or two owners of the same state across the two models.

### 4. Fire-and-Forget Analytics in Decorators

**Problem:** A `@MainActor` decorator that captured `self` inside a `Task` crashed on deallocation (the deinit-isolation runtime bug above).

**Solution:** Don't capture `self`. Hoist the `Sendable` dependency into a local and let a structured `Task` capture only that — no retain, no isolated-deinit hazard, and the task keeps its priority and context (unlike `Task.detached`, which drops them):
```swift
func play() {
    decoratee.play()
    let position = currentTime
    let logger = analyticsLogger
    Task { await logger.log(.play, position: position) }
}
```

### 5. Constraint Conflicts in Orientation Changes

**Problem:** malloc crash when constraints conflict during fullscreen.

**Solution:** Store constraints in arrays, deactivate all before activating new:
```swift
func enterFullscreen() {
    NSLayoutConstraint.deactivate(portraitConstraints)
    NSLayoutConstraint.activate(landscapeConstraints)
}
```

### 6. AVFoundation in Unit Tests

**Problem:** AVPlayer crashes in unit test environment.

**Solution:**
- Mock AVPlayerItem dependencies with protocols
- Use integration tests for real AVFoundation testing
- Stub video player in unit tests

### Anti-Patterns Summary

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Permanent bidirectional async/Combine mixing | Ownership races | One model per boundary; temporary one-way bridge OK |
| Capturing self in a Task | Isolated-deinit crash | Capture the Sendable dependency, not self |
| `@MainActor` in build settings | malloc crashes | Set `nonisolated` |
| Missing tearDown RunLoop | Test crashes | Add `RunLoop.current.run` |
| Mixed constraint states | Layout crashes | Deactivate before activate |

---

## Resources

The patterns in this codebase are applied from canonical sources:

- [Essential Feed Case Study](https://github.com/essentialdevelopercom/essential-feed-case-study) — architectural inspiration (Essential Developer)
- [The Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) & [The Principles of OOD (SOLID)](http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod) — Robert C. Martin
- [Test-Driven Development: By Example](https://www.oreilly.com/library/view/test-driven-development/0321146530/) — Kent Beck
- [Test Pyramid](https://martinfowler.com/bliki/TestPyramid.html) & [Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html) — Martin Fowler
- [Designing for tvOS — Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos) — Apple
- [App Architecture: iOS Application Design Patterns in Swift](https://www.objc.io/books/app-architecture/) — objc.io
- [Point-Free](https://www.pointfree.co) — composable architecture & Swift reactive design

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Author

**Octavio Rojas** — Lead Mobile Architect (iOS · tvOS · React Native · Kotlin).

[Portfolio](https://tattva20.github.io) · [LinkedIn](https://www.linkedin.com/in/rojastopete/) · [Writing (Medium)](https://medium.com/@tattva20) · [GitHub](https://github.com/tattva20)

This project is part of a broader body of work on disciplined, AI-augmented engineering — the [Combined Force](https://medium.com/@tattva20/combined-force-start-here-8377b2be0da4) methodology.

---

<p align="center">
  Built with TDD and Clean Architecture
</p>
