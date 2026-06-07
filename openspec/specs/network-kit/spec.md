## ADDED Requirements

### Requirement: Sutra Item Endpoint Support
The `NetworkKit` SHALL provide support for fetching sutra items for a specific album from the backend API.

#### Scenario: Requesting sutra items
- **WHEN** a request for `HTZAPI.items(sutraId: String, pageIndex: Int, pageSize: Int)` is initiated
- **THEN** the system SHALL construct a POST request to the `/get/sutra/items` endpoint
- **AND** include the `sutra_id` and pagination parameters in the request body.

### Requirement: Audio URL Formatting
The `NetworkKit` SHALL resolve the audio URL for Sutra Items using a prioritized strategy.

#### Scenario: Resolving SutraItem audio URL
- **WHEN** a `SutraItem` is processed
- **THEN** the system SHALL attempt to resolve the URL in the following order:
  - **Priority 1**: If `audio_id` (OSS ID) is present and not empty, it SHALL be prepended with `https://htz-sutra.oss-cn-shanghai.aliyuncs.com/`.
  - **Priority 2**: If `audio` (filename) is present and not empty, it SHALL be constructed as `http://htzshanghai.top/resources/audios/{sutraId}/{audio}`.
  - **Priority 3**: Otherwise, the audio URL SHALL be `nil`.
