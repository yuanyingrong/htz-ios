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
- **Critical Risk - Legacy FreeStreamer**: FreeStreamer remains only in the legacy `htz/` app. HTZNext playback is `HTZAudio.AudioEngine` (`AVPlayer` on `@MainActor`). Do not add a Swift Actor wrapper around FreeStreamer.
- **Critical Risk - Legacy ViewControllers**: The `HTZPlayViewController` and other "God Classes" SHALL be treated as critical risk areas due to their high complexity and coupling.

#### Scenario: Assessing a new change for risk
- **WHEN** a new change is proposed
- **THEN** the engineer SHALL identify if it impacts a "Critical Risk" area (legacy `htz/` FreeStreamer, or legacy ViewControllers)
- **AND** the design.md SHALL include specific mitigation steps for those risks.

#### Scenario: Changing HTZNext playback
- **WHEN** playback behavior changes in HTZNext
- **THEN** the change SHALL go through `AudioEngine` on `@MainActor` and the TCA player clients
- **AND** UI updates MUST stay on `@MainActor`.

#### Scenario: Refactoring legacy controllers
- **WHEN** logic is extracted from a legacy controller
- **THEN** the extraction SHALL be incremental
- **AND** the legacy App functionality MUST remain 100% operational after each step.
