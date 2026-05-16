## ADDED Requirements

### Requirement: Risk Management Register
The project SHALL maintain a permanent Risk Register within the Quality specification to track high-stakes areas and their mitigation strategies.

#### Scenario: Assessing a new change for risk
- **WHEN** a new change is proposed
- **THEN** the engineer SHALL identify if it impacts a "Critical Risk" area (e.g., FreeStreamer, legacy ViewControllers)
- **AND** the design.md SHALL include specific mitigation steps for those risks.

### Requirement: Critical Risk - FreeStreamer Lifecycle
The integration with the legacy `FreeStreamer` engine SHALL be treated as a critical risk area due to manual memory management and thread-safety concerns.

#### Scenario: Wrapping the audio engine
- **WHEN** the legacy engine is wrapped in a Swift Actor
- **THEN** all C-callbacks MUST be bridged carefully to async continuations
- **AND** UI updates MUST be dispatched via `@MainActor`.

### Requirement: Critical Risk - Legacy ViewControllers
The `HTZPlayViewController` and other "God Classes" SHALL be treated as critical risk areas due to their high complexity and coupling.

#### Scenario: Refactoring legacy controllers
- **WHEN** logic is extracted from a legacy controller
- **THEN** the extraction SHALL be incremental
- **AND** the legacy App functionality MUST remain 100% operational after each step.
