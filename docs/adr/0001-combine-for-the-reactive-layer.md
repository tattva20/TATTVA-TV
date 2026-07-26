# ADR 0001 — Combine for the Reactive Layer

- **Status:** Accepted
- **Date:** 2026-07-26
- **Deciders:** Project maintainer
- **Deployment target at decision time:** iOS 26.1 / tvOS 26.0

## Context

Tattva's asynchronous code is split across two Apple technologies:

- **async/await** owns the one-shot request/response work — the feed and comments loaders (`VideoLoader.load() async throws`), image loading (`VideoImageDataLoader.loadImageData(from:) throws`), and the `VideoService` facade with its local-fallback composition.
- **Combine** owns the long-lived, stream-shaped reactive layer — the playback state machine, the network / memory / performance monitors, the adaptive buffer manager, and the AVPlayer-facing adapters. These live in the platform-agnostic `StreamingCore` and `StreamingCorePlayback` frameworks and are shared by both apps.

This split is the result of a completed migration: the loaders moved off Combine to async/await, and the interim `HTTPClient → Future` bridge and the Combine image-loading helpers (`loadImageDataPublisher`, `caching`) were removed once unused. This mirrors the Essential Developer *essential-feed-case-study* lineage, whose current `LoadResourcePresentationAdapter` and `FeedService` are pure async/await with no Combine at all.

The open question this ADR settles: **should the remaining reactive layer also leave Combine — for Swift's Observation framework, or for `AsyncStream` — or does Combine stay?**

## Decision

**Keep Combine for the reactive/observability layer. Do not migrate it to Observation or wholesale to `AsyncStream`.**

The intended long-term shape is a deliberate three-tool split, each tool used where it is genuinely best:

| Concern | Tool | Examples |
|---|---|---|
| One-shot request/response | **async/await** | feed / comments / image loaders, `VideoService` |
| Continuous state + events, multi-observer, operator-driven | **Combine** | `DefaultPlaybackStateMachine`, `NetworkQualityMonitor`, `AdaptiveBufferManager`, `AVPlayerPerformanceObserver` |
| Single-consumer fire-and-forget events (where introduced) | **AsyncStream** | analytics event queue in `AnalyticsVideoPlayerDecorator` |

## Rationale

The reactive layer is genuinely stream-shaped, and Combine provides — for free and battle-tested — exactly what it needs:

- **Latest-value replay.** Six `CurrentValueSubject`s (playback state, network quality, memory state, buffer configuration, observer states) hand a new subscriber the current value immediately. A brand-new observer of the state machine must know it is currently `.playing` without waiting for the next transition.
- **Multicast.** `statePublisher` has five consumers; `qualityPublisher` and `alertPublisher` have two. `AsyncStream` is single-consumer — matching this would mean hand-building a broadcaster (register/deregister continuations, cancellation, leak-avoidance), i.e. reimplementing `Publisher`.
- **Operators.** `removeDuplicates` (×4), `receive(on:)` (×6), `map` (×37) are used across the monitors; each would be hand-rolled.
- **KVO origin.** `AVPlayerPerformanceObserver`'s upstream is AVFoundation KVO (`player.observe(\.timeControlStatus)`, item observers). Combine adapts imperative KVO callbacks cleanly; neither Observation nor `AsyncStream` improves on that boundary.

Combine is a first-class, supported Apple framework. It is not deprecated and carries no forcing function to leave it.

## Alternatives considered

### A. Migrate the reactive layer to Swift Observation — rejected

Observation (`@Observable`) is a macro on a **concrete class**, observed by reading its properties **directly** — the SwiftUI-idiomatic pattern. This codebase is deliberately **protocol-first**: `BufferManager` alone has three test fakes (`BufferManagerSpy`), and consumers depend on `any BufferManager`. Observation does not compose with existential protocol seams — you cannot observe `any BufferManager` the way you subscribe to a protocol-exposed `AnyPublisher`. Behind a protocol seam, Observation's ergonomic advantage (automatic property tracking, no manual emission) evaporates, because the protocol must still expose a stream or current-value contract. Adopting Observation would force either abandoning the seams (breaking testability) or wrapping it in pointless indirection.

This is reinforced by a deliberate stack choice: Tattva uses **UIKit**, chosen because the domain fits it better than SwiftUI. Observation is designed hand-in-glove with SwiftUI's automatic view tracking; adopting it in a UIKit + protocol-seam codebase works against the grain of the tool.

### B. Migrate the reactive layer wholesale to `AsyncStream` — rejected

`AsyncStream` fits single-consumer, payload-carrying events well, but it is single-consumer and offers no replay or operators. Replacing the multi-observer, replay-backed, operator-driven reactive layer with it means reimplementing multicast, current-value replay, and `removeDuplicates`/`receive(on:)` by hand — replacing a battle-tested framework with home-grown equivalents on the most-critical component (the playback state machine). High effort and risk for no user-visible change.

### C. Keep Combine, with deliberate boundaries — chosen

Combine for the reactive layer, async/await for loaders, `AsyncStream` for the narrow single-consumer event cases already in place. Each tool used where it is strongest.

## Consequences

**Positive**

- The reactive layer stays idiomatic, tested, and low-risk; the playback state machine — the most-tested, most-critical component — is not disturbed.
- The protocol seams that make the system testable off-device are preserved.
- The technology split is intentional and documented, not accidental.

**Trade-offs accepted**

- Combine receives no new features from Apple (maintenance posture). Accepted: the reactive needs here are stable and fully served by today's Combine.
- Two asynchronous models coexist (Combine and async/await). Accepted because the boundary is clean: async/await for one-shot work, Combine for streams, with no single piece of state owned by both.

## Revisit triggers

Reopen this decision if any of these change:

- Apple deprecates Combine or signals its removal.
- Tattva adopts SwiftUI for the surfaces that consume these streams (Observation would then earn its place).
- A new reactive component is genuinely single-consumer and payload-shaped, where `AsyncStream` is the cleaner fit (adopt it there specifically — this ADR already sanctions that).

## References

- `docs/REACTIVE-PROGRAMMING.md` — the Combine patterns in use
- Essential Developer, *essential-feed-case-study* — the async/await loader lineage this project matches
