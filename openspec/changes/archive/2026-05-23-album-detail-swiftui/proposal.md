## Why

The current home screen displays albums, but users cannot yet click on them to view the specific contents (sutra items). To complete the core user journey from discovery to content selection, we need to implement the album detail view that fetches and displays the list of items associated with a selected album.

## What Changes

- **Navigation**: Implement navigation from the `HomeView` album grid to a new `AlbumDetailView`.
- **Logic**: Create `AlbumDetailFeature` using The Composable Architecture (TCA) to manage the state and logic for fetching and displaying sutra items.
- **Networking**: Add a new case to `HTZAPI` for the `/get/sutra/items` endpoint and update `SutraItem` model to handle full resource URLs.
- **UI**: Develop a modern SwiftUI `AlbumDetailView` featuring an album header and a scrollable list of sutra items.

## Capabilities

### New Capabilities
- `album-detail`: Covers the UI, logic, and state management for viewing the specific items within an album.

### Modified Capabilities
- `home-logic`: Add actions and navigation state to handle transitioning to the album detail screen.
- `network-kit`: Add support for the sutra items API endpoint and response handling.

## Impact

- **Packages/Features/Home**: New files for album detail and navigation updates to Home feature.
- **Packages/NetworkKit**: Updates to `HTZAPI` and data models.
- **HTZNext/RootView**: Potential navigation stack updates if needed for global state.
