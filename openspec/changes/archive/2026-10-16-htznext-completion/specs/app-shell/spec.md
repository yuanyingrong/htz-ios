## MODIFIED Requirements

### Requirement: Apple Music Style Global Navigation
The app SHALL show three tabs named 首页, 专辑, and 我的, and host the now-playing bar above the tab bar.

#### Scenario: Switching tabs
- **WHEN** the user selects a tab
- **THEN** the app SHALL show the home, album list, or profile feature for that tab
- **AND** the now-playing bar SHALL stay visible when a track is loaded.

## ADDED Requirements

### Requirement: Now Playing Opens Full Player
The now-playing bar SHALL open the full-screen player.

#### Scenario: Tap the bar
- **WHEN** the user taps the now-playing bar
- **THEN** the full-screen player sheet SHALL be presented
- **AND** dismissing it SHALL leave playback unchanged.
