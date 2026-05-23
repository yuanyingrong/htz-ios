## Context

This design outlines a strictly MVP audio engine, focusing on core functionality and robust architecture. All queue-related complexity is deferred to Phase 2.

## Goals / Non-Goals

**Goals (MVP):**
- A thread-safe `AudioEngine` using Swift Actors and a single `AVPlayer`.
- A reliable `AsyncStream`-based interface for state updates with clear lifecycle.
- Basic play/pause, current item tracking, and progress reporting (in seconds).
- Correct and lazy `AVAudioSession` configuration for background audio.
- Robust error handling for playback failures.
- A minimalist, persistent player bar.

**Non-Goals (Deferred):**
- `AVQueuePlayer` and playlist management.
- Lock screen controls, full-screen UI, and advanced playback features.
- Advanced audio effects or DRM.

## Decisions

### 1. Core Technology: `AVPlayer` (for MVP)
The MVP will use a single `AVPlayer` instance.
- **Rationale**: Simplifies initial implementation, avoids queue complexities. Migration to `AVQueuePlayer` will occur in Phase 2 when queueing is required.

### 2. Concurrency & State: `Actor` with Managed `AsyncStream`
The `AudioEngine` `Actor` will:
- Manage a single `AVPlayer` and `AVPlayerItem`.
- Expose its state (`PlayerState`) via a `PassthroughSubject` (or similar) bridged to a **single `AsyncStream`** for external subscription. The `AsyncStream` will be created using `AsyncStream.makeStream(bufferingPolicy: .unbounded)`.
- **Rationale**: `Actor` ensures thread safety. `AsyncStream` is modern, but needs careful management for broadcast. Using `makeStream` with a `Continuation` owned by the `Actor` allows for controlled emission and ensures all subscribers receive updates from a single source. `PlayerClient` will be the sole subscriber to this `AsyncStream` to manage its lifecycle.

### 3. State Observation: Direct Emission & `Combine` KVO
- **`isPlaying` State**: Will be emitted directly by the `AudioEngine` when `play()` or `pause()` methods are called. We will NOT observe `player.publisher(for: \.rate)`.
- **`AVPlayerItem` Status**: KVO on `AVPlayerItem`'s `status` property (e.g., `.readyToPlay`, `.failed`) will be observed using `Combine`'s `publisher(for: \.status)` or `AsyncSequence` bridging to detect loading/error states.
- **Rationale**: Separates internal state changes from external system events. Direct emission simplifies `isPlaying` logic, while `Combine` KVO provides a safe and modern way to handle external observations.

### 4. Progress Updates: High-Frequency Timer
`AVPlayer.addPeriodicTimeObserver` will be used with an interval of **0.25 seconds** (preferredTimescale: 600) to publish playback progress (in seconds).
- **Rationale**: Provides smooth UI updates, especially for progress bars.

### 5. `AVAudioSession` Configuration: Lazy Activation
The `AVAudioSession` will be configured and activated **only upon the first `play()` call**.
- **Rationale**: Prevents the app from prematurely grabbing the audio focus on startup, avoiding unintended interruption of other audio apps or unnecessary system resource usage. The category will be `.playback` with mode `.default`.

## Risks / Trade-offs

- **[Risk] `AsyncStream` Subscriber Leakage** → **[Mitigation]** The `AudioEngine` will manage a single `Continuation`. The `PlayerClient` will be the sole external subscriber, responsible for managing its `Task` lifecycle.
- **[Risk] Playback Failures (URL, Network, Decoding)** → **[Mitigation]** The `AudioEngine` will update its `PlayerState` with a clear `error` property when `AVPlayerItem.status` transitions to `.failed` or a network issue prevents loading. This error will be propagated through the `AsyncStream`.
- **[Risk] UI Complexity in RootView** → **[Mitigation]** The `NowPlayingBarView` will be a self-contained component with its own `Store`, minimizing logic in the `RootView`.
