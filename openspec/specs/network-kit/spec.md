## ADDED Requirements

### Requirement: Sutra Item Endpoint Support
The `NetworkKit` SHALL provide support for fetching sutra items for a specific album from the backend API.

#### Scenario: Requesting sutra items
- **WHEN** a request for `HTZAPI.items(sutraId: String, pageIndex: Int, pageSize: Int)` is initiated
- **THEN** the system SHALL construct a POST request to the `/get/sutra/items` endpoint
- **AND** include the `sutra_id` and pagination parameters in the request body.

### Requirement: Audio URL Formatting
The `NetworkKit` SHALL ensure that audio URLs returned for Sutra Items are fully qualified with the Aliyun OSS base URL.

#### Scenario: Processing SutraItem audio URL
- **WHEN** a `SutraItem` is received from the API
- **THEN** its `audio` URL property SHALL be prepended with `https://htz-sutra.oss-cn-shanghai.aliyuncs.com/`
- **UNLESS** the `audio` URL already contains an `http` or `https` prefix.
