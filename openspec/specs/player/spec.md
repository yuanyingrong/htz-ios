# Player Core Specification

## Target State
The audio playback system shall be a robust, thread-safe engine encapsulated in a Swift Actor, decoupled from UI logic, and accessible via TCA dependencies.

### 1. Audio Engine (CoreAudio)
- **Safe Encapsulation**: The legacy `FreeStreamer` (OC/C) must be wrapped in a `globalActor` or `Actor` to ensure concurrency safety.
- **State Machine**: The player shall maintain a clear `PlaybackState` (idle, loading, playing, paused, error).
- **Progress Tracking**: Real-time progress (0.0 - 1.0) and duration shall be published via `AsyncStream` or `Combine`.

### 2. Queue Management
- Supports multiple play modes: `sequential`, `shuffle`, `repeatOne`, `repeatAll`.
- Handles dynamic queue updates without interrupting current playback.
- Efficiently manages local cache vs. remote streaming.

### 3. Remote Control & Info
- Full integration with `MPNowPlayingInfoCenter`.
- Handles `MPRemoteCommandCenter` events (Play, Pause, Seek, Next, Previous).
- Audio session management for background playback and interruptions (calls, other apps).

### 4. Integration
- Exposed to TCA via `AudioPlayerClient`.
- Features (Home, Album, Player) interact with the engine only through the injected client.
- Supports "Now Playing Bar" as a persistent global component.

### 5. Signed URL Playback Support
The `PlayerFeature` SHALL support playback of media items using signed streaming URLs.

#### Scenario: Initiating playback with signed URL
- **WHEN** a `.play(item)` action is dispatched containing a valid signed `URL`
- **THEN** the audio engine SHALL stream and play the audio via `AVPlayer`
- **AND** update `PlayerState.isPlaying` to true.
