# Player Core Specification

## Target State
The audio playback system shall be a robust engine on the main actor, decoupled from UI logic, and accessible via TCA dependencies.

### 1. Audio Engine
- **Implementation**: `HTZAudio.AudioEngine` wraps a single `AVPlayer` on `@MainActor` (not FreeStreamer).
- **State Machine**: The player shall maintain a clear `PlayerState` (item, playing, time, duration, rate, finished, error).
- **Progress Tracking**: Real-time progress and duration shall be published via `AsyncStream`.

### 2. Queue Management
- Supports play modes aligned with Android `playModel`: sequential (0), shuffle (1), loop (2), single (3); persisted in `UserDefaults` (`htz.playMode`).
- **Manual** previous/next always follow list order (下一集 = index ± 1, or loop wrap / single adjacent). Shuffle does **not** apply to the next/prev buttons.
- **Auto-advance** when a track finishes uses the selected mode (including shuffle random).
- Prefers local download files over signed remote URLs when present.

### 3. Remote Control & Info
- Full integration with `MPNowPlayingInfoCenter`.
- Handles `MPRemoteCommandCenter` events (Play, Pause, Seek, Next, Previous).
- Audio session management for background playback and interruptions (calls, other apps).

### 4. Integration
- Engine bridge: `@Dependency(\.playerClient)`. Cross-feature start: `@Dependency(\.playback)` / `PlayerRelay`.
- Features interact with the engine only through those clients (not by holding `AudioEngine` directly).
- Supports "Now Playing Bar" as a persistent global component; full player presentation uses Perception-safe `$store.showFullPlayer.sending(...)`.

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

#### Scenario: Manual next / previous
- **WHEN** the user taps next or previous
- **THEN** the player SHALL move to the adjacent queue index (list order)
- **AND** SHALL NOT pick a random index even if play mode is shuffle.

#### Scenario: Track finishes
- **WHEN** the current track plays to the end
- **THEN** the player SHALL auto-advance according to the current play mode (sequential next, shuffle random, loop wrap, or single replay)
- **AND** request a signed URL when the next track is not already local.

#### Scenario: Cycle play mode
- **WHEN** the user taps the play-mode control in the full-screen player
- **THEN** the mode SHALL cycle sequential → shuffle → loop → single
- **AND** the choice SHALL persist across launches.

#### Scenario: Advance fails
- **WHEN** the next track's signed URL request is denied or fails after the user (or auto-advance) left the previous track
- **THEN** the player SHALL restore the previous queue index and resume that item when possible
- **AND** the user SHALL see a paid-content or failure message.

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

### Requirement: Favorite Toggle In Player
The full-screen player SHALL show whether the current item is favorited and allow toggle.

#### Scenario: Toggle favorite
- **WHEN** the user taps the favorite control
- **THEN** the app SHALL add or delete the favorite on the server
- **AND** update the star state for the current item.

### Requirement: Resume Position
Playback MAY start at a prior listen position.

#### Scenario: Resume seek after start
- **WHEN** a play request includes a `startPosition` greater than one second
- **AND** the item duration becomes available
- **THEN** the player SHALL seek to that position once before continuing.
