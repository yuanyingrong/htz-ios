## Context

Currently, the App uses raw colors and hardcoded values across multiple UIKit view controllers. We need a unified Design System module in SwiftUI to support the modernization effort.

## Goals / Non-Goals

**Goals:**
- Define a base set of semantic color tokens.
- Establish a typography scale using SF Pro Rounded.
- Implement spacing and corner radius constants.
- Ensure all tokens are accessible from SwiftUI.

**Non-Goals:**
- Implementing complex UI components (Buttons, Cards).
- Migrating existing UIKit views to use these tokens (will be done in feature-specific changes).

## Decisions

- **Decision: SwiftUI Extensions for Tokens** → We will extend `Color` and `Font` in the `DesignSystem` module. Rationale: This provides the most idiomatic and discoverable developer experience.
- **Decision: Asset Catalog for Colors** → We will use an `.xcassets` catalog within the `DesignSystem` package for colors. Rationale: Native support for Dark Mode and easier visual management.
- **Decision: Enums for Spacing/Radius** → Use `public enum` for spacing and radius. Rationale: Type safety and clear documentation through case names (e.g., `.md`, `.lg`).

## Risks / Trade-offs

- **[Risk] Asset Catalog in SPM** → Resource management in SPM packages can sometimes be tricky with `Bundle.module`. Mitigation: Use a wrapper extension on `Color` that safely handles the bundle lookup.
- **[Risk] Naming Conflicts** → Custom extensions on `Color` might conflict with future Apple APIs. Mitigation: Use a unique prefix or clear semantic names (e.g., `htzAccent`).
