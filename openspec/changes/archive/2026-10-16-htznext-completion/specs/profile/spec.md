## ADDED Requirements

### Requirement: Profile Menu
The profile tab SHALL replace the placeholder with the account menu.

#### Scenario: Logged-in profile
- **WHEN** the profile tab appears
- **THEN** it SHALL offer favorites, listen history, notifications, settings, and profile details
- **AND** it SHALL keep logout.

### Requirement: Favorites
The user SHALL view and remove favorites, and add a favorite from album detail.

#### Scenario: Remove a favorite
- **WHEN** the user deletes a favorite
- **THEN** it SHALL disappear from the list after the server delete succeeds.

### Requirement: Listen History
The profile SHALL list listen history and allow deleting one item or all items.

#### Scenario: Clear history
- **WHEN** the user confirms clearing history
- **THEN** the list SHALL become empty after the server delete succeeds.

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
