## ADDED Requirements

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
