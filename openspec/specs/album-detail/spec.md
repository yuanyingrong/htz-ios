## ADDED Requirements

### Requirement: Album Item List Fetching
The AlbumDetailFeature SHALL fetch the list of items (songs/lessons) for a specific album using the `sutra_id`.

#### Scenario: Successful item loading
- **WHEN** the `AlbumDetailView` appears with a specific `sutraId`
- **THEN** the system SHALL trigger a request for items
- **AND** populate the state with the received `[SutraItem]` list upon success.

### Requirement: Album Metadata Display
The `AlbumDetailView` SHALL present a header containing the album's name and cover image.

#### Scenario: Displaying album header
- **WHEN** the album detail state is initialized with an `Album` object
- **THEN** the UI SHALL render the cover image using `AsyncImage`
- **AND** display the album's title prominently in the header area.

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
