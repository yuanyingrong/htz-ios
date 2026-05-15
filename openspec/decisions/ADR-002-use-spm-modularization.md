# ADR-002: Use SPM for Internal Modularization

## Status
Accepted

## Context
The legacy project is a monolithic Xcode target using CocoaPods for all dependencies. This leads to slow build times, tight coupling, and difficulty in isolating feature-specific logic.

## Decision
Use **Swift Package Manager (SPM)** to create internal modules for business logic, UI components, and core services.

## Rationale
1. **Compilation Isolation**: Faster incremental builds as unchanged packages aren't recompiled.
2. **Clear Boundaries**: Forces developers to define explicit interfaces between modules.
3. **Swift Native**: No extra tools required for internal dependency management.
4. **Testing**: Easier to write and run unit tests for isolated modules.

## Consequences
- Requires maintaining a root `Package.swift`.
- Coexistence with CocoaPods for legacy external SDKs (JPush, JShare) is necessary during the transition.
- Need to manage visibility (`public` vs `internal`) across module boundaries.
