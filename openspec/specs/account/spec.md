## ADDED Requirements

### Requirement: Bind Phone Number
A logged-in user SHALL bind a phone number with an SMS code.

#### Scenario: Successful bind
- **WHEN** the user submits a phone number and a valid code
- **THEN** the app SHALL bind it on the personal server
- **AND** sync the number to the main server.

### Requirement: Ten-Year Check-In
The profile SHALL open the existing ten-year check-in page in a web view.

#### Scenario: Open check-in
- **WHEN** the user opens 十年持志
- **THEN** the web view SHALL load `http://app.htzchina.org/tenyears/#/tenyearsHome`
- **AND** set `localStorage.unionid` to the current user's union id.

### Requirement: Feedback
The user SHALL send feedback with text and optional images.

#### Scenario: Submit feedback
- **WHEN** the user submits non-empty feedback text
- **THEN** the app SHALL upload any selected images and post the feedback
- **AND** confirm success or show the server error.

### Requirement: Reserved Apple Sign-In
The login screen SHALL show a Sign in with Apple entry without calling Apple's authorization API.

#### Scenario: Tap the reserved entry
- **WHEN** the user taps 通过 Apple 登录
- **THEN** the app SHALL explain that WeChat login is still required
- **AND** SHALL NOT start an Apple authorization request.

### Requirement: Cleartext HTTP Exception
HTZNext SHALL allow cleartext HTTP to the current main API host and the personal server host.

#### Scenario: Launch on a device
- **WHEN** the app requests those hosts over HTTP
- **THEN** App Transport Security SHALL allow the request.
