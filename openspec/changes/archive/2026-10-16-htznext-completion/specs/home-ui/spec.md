## ADDED Requirements

### Requirement: Home Search Entry
The home screen SHALL provide an entry to search.

#### Scenario: Open search
- **WHEN** the user taps the search entry on home
- **THEN** the search screen SHALL be presented.

### Requirement: Album Tab List
The album tab SHALL list the same albums as home and open the existing album detail.

#### Scenario: Open an album
- **WHEN** the user taps an album on the album tab
- **THEN** the existing album detail screen SHALL open for that album.

### Requirement: Paid Badge On Album List
Album rows SHALL show a paid or purchased badge.

#### Scenario: Unpurchased paid album
- **WHEN** an album is paid and not purchased
- **THEN** its row SHALL show 付费.

#### Scenario: Purchased album
- **WHEN** an album is paid and purchased
- **THEN** its row SHALL show 已购.
