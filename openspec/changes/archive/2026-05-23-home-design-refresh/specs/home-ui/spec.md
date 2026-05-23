## MODIFIED Requirements

### Requirement: Album Grid UI
The `HomeView` SHALL display a grid of album cards instead of a simple vertical list.

#### Scenario: Rendering albums
- **WHEN** the state contains a list of albums
- **THEN** the UI SHALL render an adaptive grid of `AlbumCardView` components
- **AND** use `DesignSystem` typography tokens (e.g., `htzHeadline` for album titles) and colors (`htzLabel` for text).
- **AND** each card SHALL feature a large artwork area with `HTZRadius.md`.
