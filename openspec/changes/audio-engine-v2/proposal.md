## Why

The legacy audio player (`FreeStreamer`) is outdated and not integrated with the modern `HTZNext` target. This change introduces a new, modern audio engine (`audio-engine-v2`) as a minimum viable product (MVP) to enable core playback functionality within the new SwiftUI architecture.

## What Changes

### MVP Scope (Phase 1):
- **New Audio Engine**: Create an `Actor`-based `AudioEngine` in the `HTZAudio` module using a single native `AVPlayer`.
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

- **Packages/HTZAudio**: Will contain the new `AudioEngine` Actor.
- **HTZNext/RootView**: Will be updated to host the `NowPlayingView` in a `ZStack`.
- **Project Configuration**: The `HTZNext` target will have the "Background Modes (Audio)" capability enabled.
- **`htz` Legacy Project**: Unaffected.
