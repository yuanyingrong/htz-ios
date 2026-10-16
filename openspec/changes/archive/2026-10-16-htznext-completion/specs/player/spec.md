## ADDED Requirements

### Requirement: Album Queue
The player SHALL keep the current album's track list and the index of the track being played.

#### Scenario: Starting an album track
- **WHEN** a track is played from an album detail
- **THEN** the player SHALL store that album's track list and select the tapped track
- **AND** request a signed audio URL before playback starts.

#### Scenario: Track finishes
- **WHEN** the current track plays to the end and a next track exists
- **THEN** the player SHALL request a signed URL for the next track and start it.

#### Scenario: Paid track blocks advance
- **WHEN** the next track's signed URL request is denied
- **THEN** playback SHALL stay on the current track
- **AND** the user SHALL see the existing paid-content message.

### Requirement: Seek And Rate
The player SHALL seek within the current item and change playback rate.

#### Scenario: Dragging the progress control
- **WHEN** the user releases a progress control at a position inside the current duration
- **THEN** playback SHALL continue from that position.

#### Scenario: Changing rate
- **WHEN** the user selects 0.75, 1, 1.25, 1.5, or 2
- **THEN** the current item SHALL play at that rate
- **AND** the selected rate SHALL remain until the user changes it.

### Requirement: Full-Screen Player
Tapping the now-playing bar SHALL open a full-screen player for the current item.

#### Scenario: Opening the full-screen player
- **WHEN** the user taps the now-playing bar
- **THEN** a sheet SHALL show artwork, title, progress, play/pause, previous, next, and rate controls bound to the same player state.

### Requirement: System Now Playing
The player SHALL publish now-playing info and handle remote commands while audio is active.

#### Scenario: Lock screen controls
- **WHEN** audio is playing and the device is locked
- **THEN** the system now-playing surface SHALL show title, album, artwork, and progress
- **AND** play, pause, next, previous, and seek commands SHALL control the same player.

### Requirement: Lyrics
The full-screen player SHALL show time-synced lyrics from the signed lyric URL.

#### Scenario: Original lyric
- **WHEN** the signed file response includes an original lyric URL
- **THEN** the player SHALL download and parse the LRC text
- **AND** highlight the line matching the current playback time.

#### Scenario: Explanation lyric
- **WHEN** the user switches to the explanation lyric and that URL exists
- **THEN** the player SHALL highlight that lyric with the same parser.

### Requirement: Listen History Reporting
The player SHALL report listen progress without blocking playback.

#### Scenario: Progress report
- **WHEN** the user pauses or the player changes track
- **THEN** the app SHALL post the item id and position in seconds to `/post/listen/history`
- **AND** a failed report SHALL leave playback running.
