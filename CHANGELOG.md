# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-25

First public release of TATTVA TV — a native iOS and tvOS streaming app built as a
working reference for disciplined, test-driven, AI-augmented mobile engineering.

### Added
- Native **iOS and tvOS** streaming: browse the video feed, open a title's detail,
  and play it back.
- **HLS playback** with AVFoundation's native adaptive bitrate; adaptive
  buffer-depth and deliberate stall-avoidance on iOS.
- iOS player controls (play/pause, ±10s seek, scrubber, volume/mute, playback
  speed, fullscreen, Picture-in-Picture) and native `AVPlayerViewController`
  controls on tvOS.
- **Accessibility** across both platforms via a reusable `StreamingCoreAccessibility`
  toolkit: VoiceOver labels, roles, combined comment elements, and feed-load
  announcements.
- Offline **metadata caching** (Core Data) with a remote-with-local-fallback loader,
  pull-to-refresh, pagination, and error/retry handling.
- **Clean Architecture** layering: a platform-agnostic `StreamingCore` (no UIKit),
  `StreamingCorePlayback` (AVFoundation), and UIKit UI layers, wired in composition
  roots.
- Unit and integration **test suites** written test-first (TDD).
- A **`CLAUDE.md` governance contract** defining how AI may touch the codebase.
- **CI** via GitHub Actions across iOS, macOS, and tvOS.

[1.0.0]: https://github.com/tattva20/TATTVA-TV/releases/tag/v1.0.0
