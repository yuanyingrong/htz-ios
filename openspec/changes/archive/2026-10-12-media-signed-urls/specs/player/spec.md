## ADDED Requirements

### Requirement: Signed URL Playback Support
The `PlayerFeature` SHALL support playback of media items using signed streaming URLs.

#### Scenario: Initiating playback with signed URL
- **WHEN** a `.play(item)` action is dispatched containing a valid signed `URL`
- **THEN** the audio engine SHALL stream and play the audio via `AVPlayer`
- **AND** update `PlayerState.isPlaying` to true.
