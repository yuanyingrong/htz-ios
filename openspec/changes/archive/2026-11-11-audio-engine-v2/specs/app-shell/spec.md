## MODIFIED Requirements

### Requirement: Apple Music Style Global Navigation
The app SHALL implement a global `TabView` (TabBar) that follows Apple Music's design patterns, and it MUST host a persistent "Now Playing" bar as an overlay.

#### Scenario: Switching Tabs with Player
- **WHEN** the user taps a TabBar item
- **THEN** the system SHALL switch to the corresponding feature view (e.g., Home, Album, Profile)
- **AND** the Now Playing bar SHALL remain visible and in the same state.

## ADDED Requirements

### Requirement: Global Player State Integration
The App Shell SHALL be responsible for integrating and hosting the global `PlayerFeature`.

#### Scenario: Initializing Player Feature
- **WHEN** the `RootView` appears
- **THEN** it SHALL instantiate the `StoreOf<PlayerFeature>`
- **AND** pass it down to the `NowPlayingBarView` overlay.
