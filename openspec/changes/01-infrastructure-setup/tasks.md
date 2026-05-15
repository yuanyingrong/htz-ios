# Tasks: Infrastructure Setup (Skeleton)

- [ ] Create `Packages` folder at the project root.
- [ ] Create subdirectory skeletons: `Packages/DesignSystem`, `Packages/NetworkKit`, `Packages/CoreAudio`.
- [ ] Initialize `Package.swift` in `Packages/` with TCA dependency and module definitions.
- [ ] Drag the `Packages` folder into the `htz` Xcode Workspace.
- [ ] Link an empty module (e.g., `DesignSystem`) to the main `htz` target to verify integration.
- [ ] Build and run the legacy App to ensure zero regression in the existing UIKit environment.

### ⛔ Out of Scope for this Change
- No creation of `HTZApp.swift` or SwiftUI `@main`.
- No implementation of Design Tokens or Network logic.
- No modification of `AppDelegate` or existing business code.
