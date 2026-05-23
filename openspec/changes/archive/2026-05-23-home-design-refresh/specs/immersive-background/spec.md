## ADDED Requirements

### Requirement: Dynamic Content Background
The Home screen SHALL feature an immersive, content-aware background that provides visual depth.

#### Scenario: Rendering immersive background
- **WHEN** the `HomeView` is displayed
- **THEN** it SHALL render a full-screen blurred background image
- **AND** the image SHOULD subtly change or blend based on the prominent content (e.g., current banner).

### Requirement: Material-Based Transparency
Navigation and overlay elements SHALL use material blurs to ensure readability against the immersive background.

#### Scenario: Applying material to toolbar
- **WHEN** scrolling content under the navigation bar
- **THEN** the system SHALL apply `.ultraThinMaterial` to the toolbar background.
