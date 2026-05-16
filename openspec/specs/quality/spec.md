# Quality Assurance Specification

## Target State
The refactored codebase shall have high test coverage, zero architectural regressions, and a automated validation pipeline.

### 1. Unit Testing (TCA)
- Every `Reducer` MUST have a corresponding test file using `TestStore`.
- All `Action` consequences (State changes and Effects) must be verified.
- Dependency mocking is mandatory for all network and side-effect calls.

### 2. Performance & Stability
- **Zero Memory Leaks**: Regular audits using Xcode Instruments.
- **Main Thread Hygiene**: All UI updates must occur on the Main Thread (MainActor); all heavy processing must be offloaded to Actors or background queues.
- **Error Handling**: Graceful degradation for network failures or audio streaming issues; user-friendly alerts using SwiftUI `.alert`.

### 3. Code Standards
- **Linter**: Strict adherence to SwiftLint (or similar tool) rules established for the project.
- **Warnings**: The project must build with zero compiler warnings in the refactored modules.
- **Documentation**: All public APIs in internal SPM modules must have DocC comments.

### 4. Regression Policy
- "Never break the build": The App must be runnable and testable at every commit.
- Manual verification is required for low-level audio logic (e.g., background audio session, lock screen controls) until automated UI tests are implemented.

### 5. Risk Management
- **Risk Register**: The project SHALL maintain a permanent Risk Register within the Quality specification to track high-stakes areas and their mitigation strategies.
- **Critical Risk - FreeStreamer Lifecycle**: The integration with the legacy `FreeStreamer` engine SHALL be treated as a critical risk area due to manual memory management and thread-safety concerns.
- **Critical Risk - Legacy ViewControllers**: The `HTZPlayViewController` and other "God Classes" SHALL be treated as critical risk areas due to their high complexity and coupling.

#### Scenario: Assessing a new change for risk
- **WHEN** a new change is proposed
- **THEN** the engineer SHALL identify if it impacts a "Critical Risk" area (e.g., FreeStreamer, legacy ViewControllers)
- **AND** the design.md SHALL include specific mitigation steps for those risks.

#### Scenario: Wrapping the audio engine
- **WHEN** the legacy engine is wrapped in a Swift Actor
- **THEN** all C-callbacks MUST be bridged carefully to async continuations
- **AND** UI updates MUST be dispatched via `@MainActor`.

#### Scenario: Refactoring legacy controllers
- **WHEN** logic is extracted from a legacy controller
- **THEN** the extraction SHALL be incremental
- **AND** the legacy App functionality MUST remain 100% operational after each step.
