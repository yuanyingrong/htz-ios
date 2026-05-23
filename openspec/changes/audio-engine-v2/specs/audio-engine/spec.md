## ADDED Requirements

### Requirement: Play/Pause Control
The audio engine SHALL provide methods to start and pause playback.

#### Scenario: Starting playback
- **WHEN** the `play()` method is called
- **THEN** the underlying `AVQueuePlayer`'s `rate` SHALL be set to 1.0
- **AND** the engine's state SHALL be updated to `isPlaying = true`.

#### Scenario: Pausing playback
- **WHEN** the `pause()` method is called
- **THEN** the `AVQueuePlayer`'s `rate` SHALL be set to 0.0
- **AND** the engine's state SHALL be updated to `isPlaying = false`.

### Requirement: Queue Management
The audio engine SHALL manage a queue of audio items.

#### Scenario: Adding an item to the queue
- **WHEN** `enqueue(item: SutraItem)` is called
- **THEN** a new `AVPlayerItem` representing that sutra item SHALL be added to the `AVQueuePlayer`.

### Requirement: State Publishing
The audio engine SHALL publish its state changes to subscribers.

#### Scenario: Playback progress update
- **WHEN** the player's time progresses
- **THEN** the engine SHALL publish the current playback time
- **AND** this value SHALL be consumed by the `PlayerFeature`.
