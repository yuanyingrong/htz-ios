## MODIFIED Requirements

### Requirement: Audio URL Formatting
The `NetworkKit` SHALL support retrieving pre-signed URLs for Sutra Items instead of relying solely on static URL string formatting.

#### Scenario: Requesting SutraItem file URL
- **WHEN** a request for `HTZAPI.sutraItemFileURL(sutraId: String, sutraItemId: String, expireSeconds: Int?)` is initiated
- **THEN** the system SHALL construct a POST request to the `/get/sutra/item/file_url` endpoint
- **AND** include `sutra_id`, `sutra_item_id`, and `expire_seconds` in the request body
- **AND** include the user's `token` in the request headers.

## ADDED Requirements

### Requirement: Sutra Cover URL Endpoint Support
The `NetworkKit` SHALL support fetching a temporary signed URL for album cover images.

#### Scenario: Requesting sutra cover signed URL
- **WHEN** a request for `HTZAPI.sutraCoverURL(sutraId: String, expireSeconds: Int?)` is initiated
- **THEN** the system SHALL construct a POST request to the `/get/sutra/cover_url` endpoint
- **AND** parse the returned `signed_url` string upon code 200.
