## Resolution (2026-11-11)

Shipped as `HTZAudio.AudioEngine`: one `AVPlayer` isolated on `@MainActor`, not a Swift `Actor`, and not a FreeStreamer wrapper. Phase 2 queue, lock screen, seek/rate, and full-screen player landed later in `htznext-completion`. Current behavior is `openspec/specs/player/spec.md` and `openspec/specs/app-shell/spec.md`. Tasks 4.5–4.7 (UI test, manual background check, rollback drill) are deferred and are not the next task.

## Why

The legacy audio player (`FreeStreamer`) is outdated and not integrated with the modern `HTZNext` target. This change introduces a new, modern audio engine (`audio-engine-v2`) as a minimum viable product (MVP) to enable core playback functionality within the new SwiftUI architecture.

## What Changes

### MVP Scope (Phase 1):
- **New Audio Engine**: `AudioEngine` in `HTZAudio` is a `@MainActor` type wrapping a single native `AVPlayer`. The earlier Swift `Actor` plan was not what shipped.
- **Core Controls**: Implement basic playback control: Play, Pause for a single URL.
- **State & Progress**: Publish the current playback state and progress (in seconds) via a robust `AsyncStream`.
- **Background Audio**: Configure the `AVAudioSession` on first playback and project capabilities to enable background playback.
- **Error Handling**: Implement basic failure reporting for invalid URLs or playback issues.
- **UI**: A simple, persistent "Now Playing" bar will be added to the UI.

### Deferred to Phase 2:
- **Queue Management**: Upgrade from `AVPlayer` to `AVQueuePlayer` to support playlists.
- **Advanced Controls**: Lock screen controls (`MPNowPlayingInfoCenter`), seeking, and rate changes.
- **Full-Screen UI**: The detailed, full-screen player view.
- **Legacy Code Removal**: Complete removal of `FreeStreamer` from the `legacy-app` codebase.

## Capabilities

### New Capabilities
- `audio-engine-mvp`: The core MVP playback logic, state publishing, background audio support, and basic error handling.
- `now-playing-bar`: Defines the compact, persistent player bar UI.

### Modified Capabilities
- `app-shell`: The root view will be modified to host the persistent `NowPlayingView` bar.

## Impact

- **Packages/HTZAudio**: Contains `AudioEngine` on `@MainActor`.
- **HTZNext/RootView**: Will be updated to host the `NowPlayingView` in a `ZStack`.
- **Project Configuration**: The `HTZNext` target will have the "Background Modes (Audio)" capability enabled.
- **`htz` Legacy Project**: Unaffected.
