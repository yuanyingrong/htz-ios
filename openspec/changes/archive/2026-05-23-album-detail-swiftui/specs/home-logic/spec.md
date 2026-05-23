## ADDED Requirements

### Requirement: Navigation to Album Detail
The `HomeFeature` SHALL support navigating to a detailed view of an album when a user selects it from the list.

#### Scenario: User selects an album
- **WHEN** the `albumTapped(Album)` action is received
- **THEN** the system SHALL update the navigation path state to include the `AlbumDetailFeature`.
