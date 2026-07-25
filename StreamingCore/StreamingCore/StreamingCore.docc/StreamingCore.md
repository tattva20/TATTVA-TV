# ``StreamingCore``

Platform-agnostic video streaming framework providing core business logic following Clean Architecture principles.

## Overview

StreamingCore is the foundation of the video streaming application, containing all platform-independent business logic. It provides a complete set of protocols, domain models, and use cases that can be implemented by any platform (iOS, macOS, tvOS).

### Design Principles

The framework follows several key architectural principles:

- **Clean Architecture**: Domain models and business rules are isolated from infrastructure concerns
- **Protocol-Oriented Design**: All major components are defined as protocols for testability and flexibility
- **Unidirectional Data Flow**: State changes flow through well-defined paths
- **Dependency Injection**: Dependencies are injected rather than created internally

### Key Features

| Feature | Description |
|---------|-------------|
| Video Loading | Protocol-based video fetching with local caching and fallback strategies |
| Playback Control | State machine-driven playback with validated transitions |
| Performance Monitoring | Real-time metrics collection with adaptive quality decisions |
| Memory Management | Automatic resource cleanup under memory pressure |
| Buffer Management | Adaptive buffering based on network and memory conditions |
| Analytics | Comprehensive playback event tracking and engagement metrics |
| Structured Logging | Multi-destination logging with configurable levels |

### Architecture Layers

```
StreamingCore — Clean Architecture; dependencies point inward to the Domain

Presentation    presenters · view-models · LoadResourcePresenter
    │ depends on
Use Case        VideoLoader · load / cache / validate use cases
    │ depends on
Domain          Video · PlaybackState — pure, no dependencies
    ▲ implements (points inward)
Infrastructure  URLSessionHTTPClient · CoreDataVideoStore · mappers
```

### Thread Safety

All public APIs are designed to be called from the main thread unless otherwise documented. Types marked with `@MainActor` enforce main thread execution. Async operations return results on the main thread.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>

### Domain Models

Core data structures representing the video streaming domain.

- ``Video``
- ``VideoComment``
- ``Paginated``

### Video Loading

Protocols and implementations for fetching video metadata.

- ``VideoLoader``
- ``VideoCache``
- ``RemoteVideoLoader``
- ``LocalVideoLoader``
- ``VideoStore``

### Image Loading

Protocols for loading and caching video thumbnails.

- ``VideoImageDataLoader``
- ``VideoImageDataCache``
- ``VideoImageDataStore``

### Playback State Machine

State machine implementation for managing playback lifecycle.

- ``VideoPlayer``
- ``PlaybackState``
- ``PlaybackAction``
- ``PlaybackError``
- ``PlaybackTransition``
- ``DefaultPlaybackStateMachine``

### Performance Monitoring

Real-time performance tracking and quality adaptation.

- ``PerformanceMonitor``
- ``PerformanceSnapshot``
- ``PerformanceAlert``
- ``PlaybackPerformanceService``
- ``RebufferingMonitor``

### Bitrate Adaptation

Intelligent bitrate selection based on network conditions.

- ``BitrateLevel``
- ``BitrateDecision``
- ``BitrateStrategy``
- ``ConservativeBitrateStrategy``
- ``NetworkQuality``

### Video Preloading

Proactive video loading for smooth playback transitions.

- ``VideoPreloader``
- ``PreloadableVideo``
- ``PreloadPriority``
- ``PredictivePreloadStrategy``
- ``AdjacentVideoPreloadStrategy``

### Buffer Management

Adaptive buffering strategies based on system conditions.

- ``BufferManager``
- ``BufferConfiguration``
- ``BufferStrategy``
- ``AdaptiveBufferManager``

### Memory Management

Monitoring and responding to memory pressure.

- ``MemoryMonitor``
- ``MemoryState``
- ``MemoryThresholds``
- ``MemoryStateProvider``
- ``PollingMemoryMonitor``

### Resource Cleanup

Automatic cleanup of resources under memory pressure.

- ``ResourceCleaner``
- ``CleanupPriority``
- ``CleanupResult``
- ``ResourceCleanupCoordinator``
- ``VideoCacheCleaner``

### Analytics

Playback analytics and engagement tracking.

- ``PlaybackAnalyticsLogger``
- ``PlaybackSession``
- ``PlaybackEvent``
- ``PlaybackEventType``
- ``EngagementMetrics``
- ``AnalyticsStore``

### Structured Logging

Comprehensive logging infrastructure.

- ``Logger``
- ``LogLevel``
- ``LogEntry``
- ``LogContext``
- ``ConsoleLogger``
- ``CompositeLogger``

### Presentation

Generic presentation layer components.

- ``LoadResourcePresenter``
- ``ResourceLoadingView``
- ``ResourceErrorView``
- ``ResourceLoadingViewModel``
- ``ResourceErrorViewModel``

### Networking

HTTP client abstraction for API communication.

- ``HTTPClient``
- ``URLSessionHTTPClient``

### Comments

Video comments feature.

- ``VideoCommentsPresenter``
- ``VideoCommentsMapper``
- ``VideoCommentsEndpoint``
