## Context

The `HTZHomeViewController` is a complex class that handles networking, table view management, and business logic. To begin the modernization, we are creating a dedicated `HomeFeature` using TCA. This feature will live in a new `Features/Home` SPM module and will be responsible for all business logic and state management for the home screen.

## Goals / Non-Goals

**Goals:**
- Implement `HomeFeature` Reducer.
- Define a robust `State` structure for the home screen.
- Create an `HomeClient` dependency that uses `NetworkKit`.
- Write exhaustive unit tests using `TestStore`.

**Non-Goals:**
- Migrating the UIKit UI code to SwiftUI (this change is logic-only).
- Changing any existing networking endpoints.

## Decisions

- **Decision: Scoped Module** → We will create `Packages/Features/Home` as an SPM module. Rationale: Keeps feature logic isolated and speeds up compilation.
- **Decision: TCA Dependency System** → We will use TCA's `@Dependency` to inject the networking client. Rationale: Allows for easy mocking in unit tests.
- **Decision: Composite State** → The `HomeFeature.State` will use enums or nested structs to manage different loading states (idle, loading, success, failure). Rationale: Prevents invalid states and makes the logic clearer.

## Risks / Trade-offs

- **[Risk] Syncing with UIKit** → Since the logic is now in TCA, we need a way to bridge this back to `HTZHomeViewController` if we want it to drive the existing UI. Mitigation: We will implement a temporary `ViewStore` bridge in the next phase, but for now, we focus on the logic in isolation.
- **[Risk] Test Coverage** → Complex networking flows can be hard to test. Mitigation: We will use the `HomeClient` as a dependency and provide a `testValue` that returns mock data.
