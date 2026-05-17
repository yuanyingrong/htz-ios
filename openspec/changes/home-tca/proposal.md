## Why

The current home screen logic is embedded within `HTZHomeViewController`, which follows a traditional imperative UIKit pattern. This makes it difficult to test, hard to maintain, and incompatible with our long-term SwiftUI goal. We need to extract the business logic into a pure, testable state machine.

## What Changes

- Create a new `Features/Home` SPM module.
- Implement the `HomeFeature` logic using TCA (State, Action, Reducer).
- Integrate with `NetworkKit` to fetch Banner and Album data.
- Provide a clear interface for the legacy `HTZHomeViewController` to eventually consume (though UI migration is out of scope for this specific change).

## Capabilities

### New Capabilities
- `home-logic`: Covers the business rules for fetching and managing data displayed on the home screen, including loading states and error handling.

## Impact

- Impact on `Packages/Package.swift` to add the new module.
- Impact on `NetworkKit` to ensure necessary models and clients are exposed.
- No immediate impact on UIKit source code (logic only migration).
