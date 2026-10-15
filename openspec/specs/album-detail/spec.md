## ADDED Requirements

### Requirement: Album Item List Fetching
The AlbumDetailFeature SHALL fetch the list of items (songs/lessons) for a specific album using the `sutra_id`.

#### Scenario: Successful item loading
- **WHEN** the `AlbumDetailView` appears with a specific `sutraId`
- **THEN** the system SHALL trigger a request for items
- **AND** populate the state with the received `[SutraItem]` list upon success.

### Requirement: Album Metadata Display
The `AlbumDetailView` SHALL present a header containing the album's name and cover image resolved from a signed URL.

#### Scenario: Displaying album header
- **WHEN** the album detail state is initialized with an `Album` object
- **THEN** the system SHALL resolve a valid signed cover URL for the album
- **AND** render the cover image using `AsyncImage` with placeholder fallback.

### Requirement: Track Tap Playback Signed URL Resolution
The `AlbumDetailFeature` SHALL request a signed file URL before sending audio items to the player store.

#### Scenario: User taps track with access granted
- **WHEN** user taps a track item that is trial or purchased
- **THEN** `AlbumDetailFeature` requests the signed audio URL from `/get/sutra/item/file_url`
- **AND** dispatches `.play` to `PlayerFeature` using the resolved signed audio URL.

#### Scenario: User taps track with access denied
- **WHEN** user taps an unpurchased paid track
- **THEN** the API returns `90001` or `access denied`
- **AND** `AlbumDetailFeature` displays an alert indicating payment/subscription is required
- **AND** playback is not initiated.

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
