## 1. Project & Background Setup

- [x] 1.1 In the `HTZNext` target, enable the "Audio, AirPlay, and Picture in Picture" background mode.

## 2. Audio Engine Core (MVP)

- [x] 2.1 Create `PlayerState.swift` to define the published player state (including `currentTime`, `duration`, `isPlaying`, `error`, `currentItem`).
- [x] 2.2 Create `AudioEngine.swift` in `HTZAudio` module as a `@MainActor` type wrapping a single `AVPlayer`.
- [x] 2.3 Implement `play(url: URL)` and `pause()` methods.
- [x] 2.4 Manage the `AVAudioSession` configuration lazily within `play(url:)`.
- [x] 2.5 Expose a single, managed `AsyncStream<PlayerState>` for publishing state, using `AsyncStream.makeStream(bufferingPolicy: .unbounded)`.
- [x] 2.6 Use `AVPlayer.addPeriodicTimeObserver` with a **0.25s** interval to publish `currentTime` and `duration` (in seconds).
- [x] 2.7 Use `Combine`'s `publisher(for:)` to observe `AVPlayerItem.status` and `AVPlayer.timeControlStatus` to publish `isPlaying` and `error` states.
- [x] 2.8 Add observers for `AVAudioSession` interruptions and route them to `PlayerState` updates.
- [x] 2.9 Add observer for `AVPlayerItem.didPlayToEndTime` notification to reset state on completion.

## 3. Player Logic & UI (MVP)

- [x] 3.1 Create a new SPM module: `PlayerFeature`.
- [x] 3.2 Define `PlayerFeature` (TCA) with state and actions for the MVP scope.
- [x] 3.3 Create `PlayerClient` as a dependency to subscribe to the `AudioEngine`'s `AsyncStream` and bridge it to TCA.
- [x] 3.4 Create `NowPlayingBarView.swift` in the `PlayerFeature` module, styled with `.ultraThinMaterial` and SF Pro Rounded fonts, showing current item title, play/pause, and progress.

## 4. App Integration & Testing

- [x] 4.1 In `RootView`, instantiate the `PlayerFeature` store.
- [x] 4.2 Use a `ZStack` to overlay the `NowPlayingBarView` above the `TabView`.
- [x] 4.3 In `AlbumDetailView`, modify the `onTapGesture` of a `SutraItemRowView` to send a "play" action to the root `PlayerFeature` (passing the item's audio URL).
- [x] 4.4 Write unit tests for `AudioEngine` on `@MainActor` to verify play/pause, progress, and error state changes.

## Deferred (2026-11-11)

Not done, and not the next task. The player has since shipped in HTZNext.

- 4.5 UI tests for `NowPlayingBarView` visibility and state. Not written.
- 4.6 Manual check of background playback and interruption handling. Not recorded here.
- 4.7 Rollback drill (remove `PlayerFeature`, the bar, and background audio, then confirm the app still builds). Obsolete once the player became the shipping path.
