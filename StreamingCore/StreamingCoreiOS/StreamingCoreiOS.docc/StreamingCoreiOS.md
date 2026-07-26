# ``StreamingCoreiOS``

iOS-specific UI components and platform adapters for video streaming applications.

## Overview

StreamingCoreiOS provides UIKit-based view controllers, views, and iOS platform adapters that implement the protocols defined in StreamingCore. It serves as the bridge between the platform-agnostic business logic and iOS-specific frameworks like AVFoundation and UIKit.

StreamingCoreiOS is purely the UIKit UI layer and imports only StreamingCore. The AVFoundation playback engine and its state, buffer, and bandwidth adapters live in the separate StreamingCorePlayback framework; StreamingCoreiOS retains only the AVFoundation UI glue (Picture-in-Picture, audio session, and the AVPlayerLayer-backed display view).

### Design Principles

- **Adapter Pattern**: Platform adapters implement StreamingCore protocols using iOS frameworks
- **Composition over Inheritance**: Views are composed of smaller, reusable components
- **Main Thread Safety**: All UI components are marked with `@MainActor` for thread safety
- **Accessibility**: UI components support VoiceOver and Dynamic Type

### Key Features

| Feature | Description |
|---------|-------------|
| Video Player UI | Full-featured player with controls, gestures, and fullscreen support |
| AVFoundation UI Glue | PiP, audio session, and an AVPlayerLayer-backed display view (the playback engine itself lives in StreamingCorePlayback) |
| Picture-in-Picture | Native PiP support for background playback |
| Network Monitoring | Real-time network quality detection using NWPathMonitor |
| Lazy Image Loading | Efficient thumbnail loading with caching |
| Comments UI | Scrollable comment list with relative timestamps |

### Architecture

```
StreamingCoreiOS — UIKit UI; depends inward on StreamingCore

UI Components     ListViewController · VideoCell · PlayerView ·
                  VideoPlayerViewController · VideoPlayerControls ·
                  PictureInPictureController · comment cells
    │ depends on
Platform Adapters AVAudioSessionAdapter · NetworkQualityMonitor
    │ depends on
StreamingCore     domain · use cases · presenters · protocols  (no UIKit)
```

### Thread Safety

All view controllers and UI components are annotated with `@MainActor` to ensure they are accessed only from the main thread. Platform adapters that interact with AVFoundation handle thread synchronization internally.

## Topics

### Video Player UI

Complete video player implementation with controls.

- ``VideoPlayerViewController``
- ``PlayerView``
- ``VideoPlayerControls``
- ``ControlsVisibilityController``

### Video List UI

Components for displaying video collections. The feed is rendered by the generic ``ListViewController`` driven by these cell controllers.

- ``VideoCell``
- ``VideoCellController``
- ``LoadMoreCell``
- ``LoadMoreCellController``

### Picture-in-Picture

Background playback support.

- ``PictureInPictureController``
- ``PictureInPictureControlling``

### Audio Session

AVFoundation audio session configuration.

- ``AVAudioSessionAdapter``
- ``AudioSessionConfiguring``
- ``AudioSessionProtocol``

### Network Monitoring

Real-time network quality tracking.

- ``NetworkQualityMonitor``

### Comments UI

Video comments display components.

- ``VideoCommentCell``
- ``VideoCommentCellController``

### Shared UI Components

Reusable UI building blocks.

- ``ListViewController``
- ``CellController``
- ``ErrorView``

### Logging

iOS-specific logging implementation.

- ``OSLogLogger``
