# Proposal: Home Feature TCA Core

## Goal
Implement the core logic for the Home screen using TCA, decoupled from the legacy `HTZHomeViewController`.

## Change
- Create `Features/Home` module.
- Implement `HomeFeature` Reducer with `onAppear`, `bannersLoaded`, and `albumsLoaded` actions.
- Write unit tests for the `HomeFeature` using `TestStore`.
