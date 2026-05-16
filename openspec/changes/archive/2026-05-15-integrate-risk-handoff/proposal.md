## Why

The previously separate `active-risks.md` file (in the deleted `handoff` folder) contained critical knowledge about project dangers and mitigation strategies. To ensure these risks are never overlooked during refactoring, they must be integrated into the core `quality` specification as a permanent "Risk Register."

## What Changes

- Re-integrate the project risk assessment into the standard OpenSpec quality framework.
- Formalize the requirement that every change must assess and mitigate known critical risks.

## Capabilities

### Modified Capabilities
- `quality`: Update to include a permanent "Risk Register" and mitigation standards for high-stakes areas (e.g., FreeStreamer, legacy ViewControllers).

## Impact

This is a documentation-only change impacting the `openspec/` directory. It improves refactoring safety by making risk management a first-class citizen of the architecture.
