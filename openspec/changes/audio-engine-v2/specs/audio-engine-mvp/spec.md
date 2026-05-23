## ADDED Requirements

### Requirement: Single Item Playback
The `AudioEngine` SHALL support playing a single audio item from a given URL.

#### Scenario: User initiates playback
- **WHEN** the `play(url: URL)` method is called
- **THEN** the `AudioEngine`'s `AVPlayer` SHALL load the item from the URL
- **AND** playback SHALL begin automatically.

### Requirement: Play/Pause Control
The audio engine SHALL provide explicit methods to start and pause playback.

#### Scenario: User pauses playback
- **WHEN** the `pause()` method is called
- **THEN** the `AVPlayer` SHALL pause
- **AND** the engine's state stream SHALL emit a new state with `isPlaying = false`.

#### Scenario: User resumes playback
- **WHEN** the `play()` method is called (without a new URL) while paused
- **THEN** the `AVPlayer` SHALL resume playback from its current position
- **AND** the state stream SHALL emit a new state with `isPlaying = true`.

### Requirement: Progress Reporting (in Seconds)
The audio engine SHALL periodically publish the current playback time and total duration in seconds.

#### Scenario: Playback is active
- **WHEN** an item is playing
- **THEN** the state stream SHALL emit new states approximately every 0.25 seconds, containing the updated `currentTime` and `duration` (both in seconds).

### Requirement: Background Audio
The application SHALL support continuous audio playback when the app is in the background.

#### Scenario: App enters background during playback
- **WHEN** the app transitions to the background during active playback
- **THEN** audio playback SHALL continue uninterrupted.

### Requirement: Audio Session Configuration (Lazy Activation)
The `AVAudioSession` SHALL be configured and activated lazily upon the first playback.

#### Scenario: First playback initiated
- **WHEN** `play(url:)` is called for the first time
- **THEN** the shared `AVAudioSession` SHALL be configured with category `.playback` and mode `.default`
- **AND** the session SHALL be activated.
- **AND** subsequent `play()` calls SHALL NOT reconfigure or reactivate the session.

### Requirement: State Stream Lifecycle
The `AudioEngine` SHALL manage a single, broadcast `AsyncStream` for its state, ensuring all current subscribers receive updates.

#### Scenario: Multiple `PlayerClient` subscriptions
- **WHEN** multiple `PlayerClient` instances (e.g., in different parts of the UI for testing) subscribe to the `AudioEngine`'s state
- **THEN** they SHALL all receive the same sequence of `PlayerState` updates from a single, underlying source.
- **AND** the `AsyncStream`'s `Continuation` SHALL be managed internally by the `AudioEngine` and only terminate upon its deinitialization.

### Requirement: Playback Failure Reporting
The audio engine SHALL report failures during playback or resource loading.

#### Scenario: Invalid URL provided
- **WHEN** `play(url:)` is called with an invalid or unreachable URL
- **THEN** the state stream SHALL emit a `PlayerState` with `isPlaying = false` and a non-nil `error` property.

#### Scenario: Playback item fails
- **WHEN** an `AVPlayerItem` fails to load or encounters an error during playback
- **THEN** the state stream SHALL emit a `PlayerState` with `isPlaying = false` and a non-nil `error` property.

### Requirement: Playback Completion
The engine SHALL correctly report when an audio item has finished playing.

#### Scenario: Item finishes playing
- **WHEN** the current `AVPlayerItem` reaches its end time
- **THEN** the state stream SHALL emit a new state with `isPlaying = false`, `currentTime = 0`, and `duration = 0`.
