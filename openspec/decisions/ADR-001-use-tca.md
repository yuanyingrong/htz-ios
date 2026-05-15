# ADR-001: Use The Composable Architecture (TCA)

## Status
Accepted

## Context
The legacy application suffers from "God Views" (e.g., `HTZPlayViewController`), heavy use of singletons, and fragmented communication patterns (Delegates, Notifications, didSet). This makes state synchronization difficult and testing nearly impossible.

## Decision
Adopt **The Composable Architecture (TCA)** as the primary state management framework for the modernized application.

## Rationale
1. **Unidirectional Data Flow**: Ensures state changes are predictable and easy to debug.
2. **Testability**: Provides `TestStore` for exhaustive unit testing of business logic.
3. **Modularity**: Naturally supports feature decomposition and composition.
4. **SwiftUI First**: Deeply integrated with SwiftUI's state management primitives.
5. **Standardization**: Reduces developer cognitive load by providing a consistent pattern for all features.

## Consequences
- Requires a learning curve for developers unfamiliar with functional programming or Redux-like patterns.
- Adds boilerplate for simple features.
- Tight coupling with the TCA library (mitigated by its widespread adoption and stability).
