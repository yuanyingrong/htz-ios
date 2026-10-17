## ADDED Requirements

### Requirement: Download A Track Or Album
The user SHALL download one chapter or every chapter of the current album.

#### Scenario: Download one chapter
- **WHEN** the user downloads a chapter whose signed audio URL is available
- **THEN** the file SHALL be saved in the app sandbox and listed under downloads.

#### Scenario: Download progress
- **WHEN** a download is in progress
- **THEN** the download list SHALL show that item as in progress until it finishes or fails.

### Requirement: Offline Playback
A downloaded chapter SHALL play from the local file.

#### Scenario: Play a downloaded chapter
- **WHEN** the user plays a chapter that has a completed local file
- **THEN** the player SHALL use that file URL
- **AND** SHALL NOT request a new signed audio URL.

#### Scenario: Play from download list
- **WHEN** the user taps a finished download in the profile download list
- **THEN** the player SHALL open that local file.

### Requirement: Download Management
The download list SHALL allow pause, resume/retry, and delete.

#### Scenario: Pause and resume
- **WHEN** the user pauses an in-progress download
- **THEN** the item SHALL show paused
- **AND** resume SHALL continue or restart from the saved remote URL.

#### Scenario: Delete download
- **WHEN** the user deletes a download
- **THEN** the local file and list entry SHALL be removed.

### Requirement: No Local Encryption In This Change
Downloaded audio SHALL stay as a normal media file in the sandbox.

#### Scenario: Completed download
- **WHEN** a download finishes
- **THEN** the app SHALL NOT encrypt the file into an `.htze` container.
