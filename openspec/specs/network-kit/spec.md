## ADDED Requirements

### Requirement: Sutra Item Endpoint Support
The `NetworkKit` SHALL provide support for fetching sutra items for a specific album from the backend API.

#### Scenario: Requesting sutra items
- **WHEN** a request for `HTZAPI.items(sutraId: String, pageIndex: Int, pageSize: Int)` is initiated
- **THEN** the system SHALL construct a POST request to the `/get/sutra/items` endpoint
- **AND** include the `sutra_id` and pagination parameters in the request body.

### Requirement: Audio URL Formatting
The `NetworkKit` SHALL support retrieving pre-signed URLs for Sutra Items instead of relying solely on static URL string formatting.

#### Scenario: Requesting SutraItem file URL
- **WHEN** a request for `HTZAPI.sutraItemFileURL(sutraId: String, sutraItemId: String, expireSeconds: Int?)` is initiated
- **THEN** the system SHALL construct a POST request to the `/get/sutra/item/file_url` endpoint
- **AND** include `sutra_id`, `sutra_item_id`, and `expire_seconds` in the request body
- **AND** include the user's `token` in the request headers.

### Requirement: Sutra Cover URL Endpoint Support
The `NetworkKit` SHALL support fetching a temporary signed URL for album cover images.

#### Scenario: Requesting sutra cover signed URL
- **WHEN** a request for `HTZAPI.sutraCoverURL(sutraId: String, expireSeconds: Int?)` is initiated
- **THEN** the system SHALL construct a POST request to the `/get/sutra/cover_url` endpoint
- **AND** parse the returned `signed_url` string upon code 200.

### Requirement: Album Paid Fields
`Album` SHALL decode and keep `description`, `isPaid`, `price`, `isPurchased`, and `paidUrl` from the sutra list response.

#### Scenario: Rebuilding an album after cover resolution
- **WHEN** a signed cover URL replaces the raw cover path
- **THEN** the rebuilt album SHALL keep the paid fields from the original response.

### Requirement: Library And Account Endpoints
NetworkKit SHALL call the existing listen-history, favorite, notification, profile, search, feedback, and phone-binding endpoints.

#### Scenario: Authorized request
- **WHEN** any of these endpoints is called and a token exists
- **THEN** the request SHALL send that token in the `token` header.
