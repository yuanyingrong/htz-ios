# Next Priority

## Immediate Goal
The next step is to establish the **Modern Infrastructure Skeleton (Phase 1, Step 1)**.

## Active Change
- **ID**: `01-infrastructure-setup`
- **Location**: `openspec/changes/01-infrastructure-setup/`

## Objective
Create the `Packages/` directory, establish empty skeleton modules (DesignSystem, NetworkKit, CoreAudio), and initialize the `Package.swift` manifest with TCA dependencies.

## Why this one?
This is a prerequisite for all subsequent refactoring steps. We cannot implement new features without the modular SPM infrastructure. The scope has been significantly narrowed to ensure zero risk to the existing app.

## Strict Boundaries
- **ONLY** SPM skeleton setup is allowed.
- **SwiftUI Entry Migration** (e.g., `HTZApp.swift`, `RootView`) is explicitly postponed.
- **DO NOT** modify the existing UIKit App lifecycle (`AppDelegate`, `SceneDelegate`, etc.).
- **DO NOT** write any actual business logic or design tokens yet.

## Success Criteria
1. `Packages/` folder exists with skeleton subdirectories.
2. `Package.swift` is valid and includes TCA.
3. The project compiles with the new SPM dependency linked to the main target.
4. The legacy UIKit application launches and runs identically to before.
