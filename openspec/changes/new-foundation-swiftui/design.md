## Context

We are abandoning the legacy UIKit project shell in favor of a clean, modern SwiftUI-first project. All previous modernization efforts (SPM modules, design tokens, network kit) are ready to be integrated into this new shell.

## Goals / Non-Goals

**Goals:**
- Move legacy code to a non-compiling directory (`legacy-app/`).
- Create a pure SwiftUI Xcode Project.
- Implement the `HTZApp` entry point.
- Implement a `RootView` with a basic `TabView` (Home, Album, Profile).
- Display the existing `HomeView` as the first tab.

**Non-Goals:**
- Implementing the Album or Profile features yet (they will use placeholders).
- Migrating legacy business logic during this change.

## Decisions

- **Decision: Zero CocoaPods** → The new target will NOT use CocoaPods. Rationale: Maintain absolute purity and avoid the symbol collision issues encountered previously.
- **Decision: SPM for everything** → All dependencies (TCA, Moya, etc.) and all internal features will be managed via the existing `Packages/Package.swift`.
- **Decision: Minimal Shell** → The main App Target will contain minimal code: just the `@main` struct and the `RootView` orchestration.

## Risks / Trade-offs

- **[Risk] Asset Loss** → Some images from the old `Assets.xcassets` might be needed. Mitigation: We will manually copy only the necessary icons (tab bar icons, app icon) from the legacy folder as we need them.
- **[Risk] Xcode Project Management** → Generating a new project from CLI is complex. Mitigation: We will create the new project at the root level so it can easily reference the `Packages/` folder.
