## ADDED Requirements

### Requirement: Immersive Hero Header
The `AlbumDetailView` SHALL feature a prominent hero header that reacts to scroll gestures.

#### Scenario: Scrolling up
- **WHEN** the user scrolls the content upwards
- **THEN** the album cover image SHALL scale down smoothly
- **AND** the navigation bar SHALL transition to an `.ultraThinMaterial` appearance.

### Requirement: High-Density Track List
The list of sutra items SHALL be rendered using a clear typographic hierarchy inspired by Apple Music Classical.

#### Scenario: Rendering track rows
- **WHEN** the album items are loaded
- **THEN** each row SHALL display a sequential index number, a primary title, and secondary metadata (e.g., duration).
- **AND** use SF Pro Rounded font with weight variations to distinguish information levels.

### Requirement: Context-Aware Immersive Background
The `AlbumDetailView` SHALL use the `ImmersiveBackgroundView` logic to create a full-screen blurred background derived from the album artwork.

#### Scenario: Initializing detail view
- **WHEN** the view appears
- **THEN** the background SHALL be set to a blurred version of the album cover to provide visual depth.
