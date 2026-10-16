# Player Core Specification

## Target State
The audio playback system shall be a robust, thread-safe engine encapsulated in a Swift Actor, decoupled from UI logic, and accessible via TCA dependencies.

### 1. Audio Engine (CoreAudio)
- **Safe Encapsulation**: The legacy `FreeStreamer` (OC/C) must be wrapped in a `globalActor` or `Actor` to ensure concurrency safety.
- **State Machine**: The player shall maintain a clear `PlaybackState` (idle, loading, playing, paused, error).
- **Progress Tracking**: Real-time progress (0.0 - 1.0) and duration shall be published via `AsyncStream` or `Combine`.

### 2. Queue Management
- Supports multiple play modes: `sequential`, `shuffle`, `repeatOne`, `repeatAll`.
- Handles dynamic queue updates without interrupting current playback.
- Efficiently manages local cache vs. remote streaming.

### 3. Remote Control & Info
- Full integration with `MPNowPlayingInfoCenter`.
- Handles `MPRemoteCommandCenter` events (Play, Pause, Seek, Next, Previous).
- Audio session management for background playback and interruptions (calls, other apps).

### 4. Integration
- Exposed to TCA via `AudioPlayerClient`.
- Features (Home, Album, Player) interact with the engine only through the injected client.
- Supports "Now Playing Bar" as a persistent global component.

### 5. Signed URL Playback Support
The `PlayerFeature` SHALL support playback of media items using signed streaming URLs.

#### Scenario: Initiating playback with signed URL
- **WHEN** a `.play(item)` action is dispatched containing a valid signed `URL`
- **THEN** the audio engine SHALL stream and play the audio via `AVPlayer`
- **AND** update `PlayerState.isPlaying` to true.

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
