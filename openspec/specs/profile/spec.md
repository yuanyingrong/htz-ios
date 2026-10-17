## ADDED Requirements

### Requirement: Profile Menu
The profile tab SHALL replace the placeholder with the account menu.

#### Scenario: Logged-in profile
- **WHEN** the profile tab appears
- **THEN** it SHALL offer favorites, listen history, notifications, settings, and profile details
- **AND** it SHALL keep logout.

### Requirement: Favorites
The user SHALL view and remove favorites, toggle favorite from album/player, and play from the favorites list.

#### Scenario: Remove a favorite
- **WHEN** the user deletes a favorite
- **THEN** it SHALL disappear from the list after the server delete succeeds.

#### Scenario: Play a favorite
- **WHEN** the user taps a favorite row
- **THEN** the player SHALL start a queue built from the favorites list at that item.

### Requirement: Listen History
The profile SHALL list listen history, allow deleting one item or all items, and resume playback from a history row.

#### Scenario: Clear history
- **WHEN** the user confirms clearing history
- **THEN** the list SHALL become empty after the server delete succeeds.

#### Scenario: Play from history
- **WHEN** the user taps a history row
- **THEN** the player SHALL play that chapter
- **AND** seek to the stored last position (seconds or millisecond values ≥ 100000 treated as ms).

### Requirement: Notifications
The profile SHALL list notifications and mark them read.

#### Scenario: Open a notification
- **WHEN** the user opens an unread notification
- **THEN** the app SHALL mark it read and show its content.

### Requirement: Settings And Profile Details
Settings SHALL link to the about page, user agreement, and privacy policy. Profile details SHALL load and save avatar, nickname, and signature.

#### Scenario: Save nickname
- **WHEN** the user saves a new nickname
- **THEN** the profile header SHALL show the saved nickname.
