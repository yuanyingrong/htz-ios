## ADDED Requirements

### Requirement: Persistent Visibility
A compact player bar SHALL be displayed persistently above the `TabView` when there is an active audio item.

#### Scenario: An item is playing
- **WHEN** the global `PlayerFeature` state indicates `currentItem` is not nil
- **THEN** the `NowPlayingBarView` SHALL be visible across all tabs.

#### Scenario: Playback is stopped/cleared
- **WHEN** the `currentItem` in the player state becomes nil
- **THEN** the `NowPlayingBarView` SHALL be hidden.

### Requirement: Modern Apple Aesthetic
The player bar SHALL adhere to the project's Design Constitution.

#### Scenario: Rendering the player bar
- **WHEN** the player bar is visible
- **THEN** its background SHALL use `.ultraThinMaterial` to create a blurred, translucent effect.
- **AND** it SHALL display the current track's title and artist/album using SF Pro Rounded typography.
- **AND** a progress indicator (e.g., a thin line at the top) SHALL reflect the current playback progress.
