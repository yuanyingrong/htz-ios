## Why

The current `HomeView` uses a basic list-based layout that lacks the premium, immersive feel of modern Apple media apps. To align with our updated "Design Constitution," we need to upgrade the home screen UI to feature card-based layouts and immersive visual elements inspired by Apple Podcasts and Apple TV.

## What Changes

- **Card-Based Grid**: Replace the simple `AlbumRowView` list with a modern `AlbumCardView` displayed in a grid or organized horizontal sections (Podcasts style).
- **Immersive Background**: Implement a dynamic, blurred background that responds to content or the selected hero banner (Apple TV style).
- **Material Design**: Apply `.ultraThinMaterial` to navigation bars and overlay elements to enhance depth.
- **Enhanced Typography**: Refine the spacing and font usage to better match SF Pro Rounded standards.

## Capabilities

### New Capabilities
- `immersive-background`: Reusable logic/view for creating content-aware blurred backgrounds.

### Modified Capabilities
- `home-ui`: Update the layout requirements to transition from a list to a card-based grid/sectioned structure.

## Impact

- **Packages/Features/Home**: Significant UI component refactoring.
- **Packages/DesignSystem**: Potential addition of new material-based styling helpers.
