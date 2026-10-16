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

### Requirement: Android-Style Album Detail
Album detail SHALL show the cover and description, sort, episode picker, and download actions, a resume row when this album has listening history, and a chapter list. Tapping a chapter SHALL open the full player.

#### Scenario: Open a chapter
- **WHEN** the user taps a chapter
- **THEN** playback of that chapter SHALL start
- **AND** the full player SHALL be presented with the chapter title, lyrics, and transport controls.

#### Scenario: Resume row
- **WHEN** listening history contains a chapter from this album
- **THEN** the detail screen SHALL show a 续播 row for that chapter.

### Requirement: Album Tab Grid
The album tab SHALL list albums in a three-column grid and show the most recently listened album above the grid.

#### Scenario: Continue listening
- **WHEN** the user has a listening history and taps 继续收听
- **THEN** that album's detail SHALL open.

### Requirement: Album Queue Handoff
Opening a track from album detail SHALL give the player the whole chapter list, not only the tapped item.

#### Scenario: Tap a playable chapter
- **WHEN** the signed audio URL for the tapped chapter is returned
- **THEN** album detail SHALL send that chapter plus the current chapter list to the player.

### Requirement: Paid Album Badge
Album detail SHALL show whether the album is paid and whether the current user has purchased it.

#### Scenario: Unpurchased paid album
- **WHEN** the album is paid and not purchased
- **THEN** the detail header SHALL show 付费.

#### Scenario: Purchased paid album
- **WHEN** the album is paid and purchased
- **THEN** the detail header SHALL show 已购.
