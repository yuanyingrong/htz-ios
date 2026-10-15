## MODIFIED Requirements

### Requirement: Album Metadata Display
The `AlbumDetailView` SHALL present a header containing the album's name and cover image resolved from a signed URL.

#### Scenario: Displaying album header
- **WHEN** the album detail state is initialized with an `Album` object
- **THEN** the system SHALL resolve a valid signed cover URL for the album
- **AND** render the cover image using `AsyncImage` with placeholder fallback.

## ADDED Requirements

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
