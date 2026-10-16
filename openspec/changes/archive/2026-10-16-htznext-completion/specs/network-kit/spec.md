## ADDED Requirements

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
