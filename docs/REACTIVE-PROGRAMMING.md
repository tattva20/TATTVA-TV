# Reactive Programming with Combine in Tattva

This document explains the Combine patterns and reactive programming practices used throughout the Tattva codebase.

---

## Overview

Tattva uses Apple's **Combine framework** for **observation and state streams**. The video feed and comments loaders now use async/await; Combine backs the parts of the system that are genuinely stream-shaped:
- Playback state and transition streams
- Buffer, memory, and performance monitoring
- Resource cleanup events
- Main-thread dispatch helper (`CombineHelpers.swift`)

These streams live in the platform-agnostic cores (`StreamingCore` and `StreamingCorePlayback`) and are shared by both the iOS (`Tattva`) and tvOS (`TattvaTV`) apps.

> **Why Combine here (and not Observation or AsyncStream)?** See [ADR 0001 — Combine for the Reactive Layer](adr/0001-combine-for-the-reactive-layer.md) for the decision, the alternatives weighed, and the triggers that would reopen it. The AVPlayer-facing Combine plumbing — `StatefulVideoPlayer.statePublisher`, `AVPlayerStateAdapter`, `AVPlayerPerformanceObserver`, `AVPlayerBufferAdapter` — lives in `StreamingCorePlayback`.

---

## Publisher Types Used

| Publisher | Purpose | Example |
|-----------|---------|---------|
| `CurrentValueSubject` | State storage with current value access | `PlaybackState` |
| `PassthroughSubject` | Event streams without state | `PlaybackTransition` |
| `AnyPublisher` | Type-erased publisher for observation | `statePublisher` |

---

## 1. State Publishing with CurrentValueSubject

### PlaybackState Publishing

```swift
@MainActor
public final class DefaultPlaybackStateMachine {
    private let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)

    public var currentState: PlaybackState { stateSubject.value }

    public var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public func send(_ action: PlaybackAction) -> PlaybackTransition? {
        guard let nextState = nextState(for: action, from: stateSubject.value) else {
            return nil
        }
        stateSubject.send(nextState)
        return transition
    }
}
```

**Why CurrentValueSubject?**
- Stores current value (accessible via `.value`)
- New subscribers immediately receive current state
- Perfect for UI state bindings

---

## 2. Event Streams with PassthroughSubject

```swift
@MainActor
public final class DefaultPlaybackStateMachine {
    private let transitionSubject = PassthroughSubject<PlaybackTransition, Never>()

    public var transitionPublisher: AnyPublisher<PlaybackTransition, Never> {
        transitionSubject.eraseToAnyPublisher()
    }

    public func send(_ action: PlaybackAction) -> PlaybackTransition? {
        transitionSubject.send(transition)
        return transition
    }
}
```

**Why PassthroughSubject?** No stored value, only emits to current subscribers - perfect for events.

---

## 3. Combine Helpers

**File:** `StreamingCore/StreamingCore/Shared Combine/CombineHelpers.swift`

Two reusable helpers back the Combine surfaces. `dispatchOnMainThread()` delivers downstream on the main thread, running synchronously when already on it (used by `PerformanceMonitor`):

```swift
public extension Publisher {
    func dispatchOnMainThread() -> AnyPublisher<Output, Failure> {
        receive(on: DispatchQueue.immediateWhenOnMainThreadScheduler).eraseToAnyPublisher()
    }
}
```

`loadImageDataPublisher(from:)` bridges the synchronous `VideoImageDataLoader` into a publisher:

```swift
public extension VideoImageDataLoader {
    typealias Publisher = AnyPublisher<Data, Error>

    func loadImageDataPublisher(from url: URL) -> Publisher {
        Deferred {
            Future { completion in
                completion(Result { try self.loadImageData(from: url) })
            }
        }
        .eraseToAnyPublisher()
    }
}
```

---

## 4. Functional Side-Effects

Image data flows through a Combine caching helper — a `handleEvents` side-effect that writes successful loads to the cache:

```swift
public extension Publisher where Output == Data {
    func caching(to cache: VideoImageDataCache, for url: URL) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { data in
            try? cache.save(data, for: url)
        }).eraseToAnyPublisher()
    }
}
```

---

## 5. Feed and Comments Loading

The feed and comments loaders are **not** Combine. They compose with async/await — remote fetch, cache write, and local fallback expressed directly:

```swift
public func loadRemoteVideosWithLocalFallback() async throws -> Paginated<Video> {
    do {
        let items = try await loadRemoteVideos()
        try? localVideoLoader.save(items)
        return makeFirstPage(items: items)
    } catch {
        return makeFirstPage(items: try localVideoLoader.load())
    }
}
```

Defined in `StreamingCore/StreamingCorePlayback/VideoService.swift`.

---

## 6. State Publisher Subscriptions

`ResourceCleanupCoordinator` (`StreamingCore/Resource Cleanup Feature/ResourceCleanupCoordinator.swift`) subscribes to a memory `statePublisher` to drive cleanup under pressure:

```swift
monitoringCancellable = memoryMonitor.statePublisher
    .receive(on: RunLoop.main)
    .sink { [weak self] state in
        guard let self = self else { return }
        let thresholds = MemoryThresholds.default
        let pressureLevel = state.pressureLevel(thresholds: thresholds)
        // dispatch cleanup for pressureLevel...
    }
```

`StatefulVideoPlayer` (`StreamingCorePlayback/StatefulVideoPlayer.swift`) instead re-publishes `stateMachine.statePublisher` so UI can observe playback state without touching the state machine directly.

---

## 7. Common Pitfalls

### Forgetting to Store Cancellables

```swift
// Bad - subscription immediately cancelled
publisher.sink { value in }

// Good - stored
publisher.sink { value in }.store(in: &cancellables)
```

### Strong Reference Cycles

```swift
// Bad
publisher.sink { state in self.updateUI(state) }

// Good
publisher.sink { [weak self] state in self?.updateUI(state) }
```

### Not Dispatching to Main Thread

```swift
// Bad
networkPublisher.sink { [weak self] data in self?.label.text = data }

// Good
networkPublisher.receive(on: DispatchQueue.main).sink { ... }
```

---

## Related Documentation

- [State Machines](STATE-MACHINES.md) - State publishing patterns
- [Architecture](ARCHITECTURE.md) - Where Combine fits in layers
- [TDD](TDD.md) - Testing publishers

---

## References

- [Combine Framework - Apple](https://developer.apple.com/documentation/combine)
