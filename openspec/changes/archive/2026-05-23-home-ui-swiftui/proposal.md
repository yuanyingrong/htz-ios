## Why

The current home screen (`HTZHomeViewController`) is built using legacy UIKit and SnapKit, which is difficult to maintain and inconsistent with our target SwiftUI architecture. Having completed the `HomeFeature` logic and `DesignSystem` tokens, it is time to build the modern, reactive SwiftUI interface that binds to this logic.

## What Changes

- Implement `HomeView` using SwiftUI in the `Home` SPM module.
- Utilize the `DesignSystem` tokens (Colors, Typography, Spacing) for all visual styling.
- Create modular UI components (e.g., `BannerCarouselView`, `AlbumGridView`) bound to the TCA `HomeFeature.State`.
- **Bridge**: Provide a mechanism (e.g., `UIHostingController`) so the legacy `HTZHomeViewController` or Main TabBar can present the new SwiftUI view.

## Capabilities

### New Capabilities
- `home-ui`: Defines the visual representation, layout, and user interactions of the Home screen using SwiftUI.

## Impact

- **UI**: Replaces the visual layer of the home screen.
- **Dependencies**: The `Home` module will now depend on the `DesignSystem` module.
- **Legacy Integration**: The main UIKit app will import the `Home` module to present the `HomeView`.
