## ADDED Requirements

### Requirement: SwiftUI View Integration
The HomeFeature SHALL provide a SwiftUI `HomeView` that is initialized with a `StoreOf<HomeFeature>`.

#### Scenario: View Initialization
- **WHEN** the `HomeView` is instantiated
- **THEN** it SHALL accept a TCA `Store`
- **AND** it SHALL bind to the state and actions of that store.

### Requirement: Android-Style Home Layout
The home screen SHALL follow the Android home: a search field, recommended albums as wide cover banners, recent listening history, check-in stats, and study stats on a flat page background.

#### Scenario: Recommended albums
- **WHEN** albums have loaded
- **THEN** the home screen SHALL show at most three of them under 推荐专辑 as wide cover banners with the album name over the artwork
- **AND** tapping a banner SHALL open that album's detail.

#### Scenario: Recent listening history
- **WHEN** the user has listening history
- **THEN** the home screen SHALL show up to three recent items with cover, title, album name, and a play control
- **AND** tapping an item SHALL start playback of that chapter.

#### Scenario: Check-in and study stats
- **WHEN** the home screen appears for a logged-in user
- **THEN** it SHALL show 打卡统计 (continuous, this month, total, and the last seven days) from the ten-year check-in service
- **AND** it SHALL show 学习统计 (total duration, completed lessons, today, this week, this month, and a seven-day chart) from the study service
- **AND** 去打卡 SHALL open the ten-year check-in page.

### Requirement: Loading and Error States
The UI SHALL reflect the loading and error states defined in the `HomeFeature` logic.

#### Scenario: Displaying loading state
- **WHEN** `state.isLoading` is true
- **THEN** the UI SHALL display a `ProgressView` or loading indicator.

#### Scenario: Displaying error state
- **WHEN** `state.errorMessage` is present
- **THEN** the UI SHALL display the error text
- **AND** use the `htzLabel` color or an appropriate error semantic color if defined.

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
