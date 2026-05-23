## ADDED Requirements

### Requirement: Persistent Player Bar
A compact, persistent player bar (Now Playing bar) SHALL be displayed above the main TabView.

#### Scenario: Bar visibility
- **WHEN** there is an active audio item in the queue
- **THEN** the Now Playing bar SHALL be visible on all tabs.
- **AND** it SHALL be hidden when the queue is empty.

### Requirement: Full-Screen Player Presentation
Tapping the Now Playing bar SHALL present a full-screen player view.

#### Scenario: Presenting full-screen player
- **WHEN** the user taps the compact Now Playing bar
- **THEN** a modal view containing the full player UI SHALL be presented.

### Requirement: Playback Controls
The UI SHALL provide standard playback controls.

#### Scenario: Tapping play/pause
- **WHEN** the user taps the play/pause button in either the compact or full-screen view
- **THEN** the corresponding action SHALL be sent to the `PlayerFeature`.
