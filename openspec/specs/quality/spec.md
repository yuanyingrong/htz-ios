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
