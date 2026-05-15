# Active Risks

## 🔴 Critical Risks

### 1. FreeStreamer Lifecycle Risk
- **Description**: `FreeStreamer` is an Objective-C/C library with manual memory management.
- **Risk**: Wrapping it in a Swift Actor might lead to race conditions if the C-callbacks interact with Main Thread objects inappropriately, or memory leaks if closures capture the streamer incorrectly.
- **Mitigation**: Use `CheckedContinuation` carefully and ensure all UI updates from the actor are dispatched via `MainActor`.

### 2. HTZPlayViewController Complexity
- **Description**: This class is deeply intertwined with almost all app systems (Audio, UI, Network, Share).
- **Risk**: Attempting to refactor it too early or all at once will break core App functionality.
- **Mitigation**: This must be the **last** page migrated. We will extract its logic into TCA actions gradually, first as dependencies.

## 🟠 High Risks

### 3. TCA Scope Creep
- **Description**: TCA can become overly complex if state is shared unnecessarily across deep trees.
- **Risk**: Creating a monolithic "Global State" that makes the App sluggish or hard to maintain.
- **Mitigation**: Keep features scoped. Use `Shared` state only where absolutely necessary (e.g., Now Playing).

### 4. SwiftUI/UIKit Navigation Hybrid Risk
- **Description**: Managing a stack that mixes `UINavigationController` and `NavigationStack`.
- **Risk**: Broken back buttons, navigation bar double-headers, or memory leaks from unreleased View Controllers.
- **Mitigation**: Strictly use `UIHostingController` and `UIViewControllerRepresentable` with clean deinit logic.

### 5. Design System Inconsistency
- **Description**: The team might bypass tokens for "quick fixes."
- **Risk**: UI becoming fragmented again, defeating the purpose of the refactor.
- **Mitigation**: Code reviews must enforce token usage. No raw `Color` or `Font` initializers in Features.
