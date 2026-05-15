# ADR-005: Design System Token Strategy

## Status
Accepted

## Context
UI styling is currently hardcoded in ViewControllers using raw colors and magic numbers for spacing/radius.

## Decision
Implement a **Centralized Token System** within a dedicated `DesignSystem` SPM module.

## Rationale
1. **Consistency**: Ensures all new SwiftUI views use the same colors, fonts, and spacing.
2. **Maintenance**: Allows project-wide style changes (e.g., brand color update) by editing a single file.
3. **Dark Mode**: Simplifies Dark Mode support through semantic color naming.
4. **Developer Experience**: Auto-completion for tokens reduces errors and speeds up UI development.

## Consequences
- Requires a one-time effort to define and map all tokens.
- Legacy UIKit views won't automatically benefit unless manually refactored to use the tokens (via bridge extensions).
