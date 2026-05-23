## Why

The current project architecture is hindered by legacy UIKit/CocoaPods configurations and an outdated deployment target (iOS 13). Attempting to bridge modern SwiftUI/TCA code into this legacy chassis has proven to be high-friction. Since the app has not yet launched, we are choosing a "Clean Break" strategy: re-initializing the project as a modern, pure-SwiftUI application while preserving the old code in a `legacy-app` folder for reference only.

## What Changes

- **Renaming**: Move the existing `htz/` directory to `legacy-app/`.
- **New Project**: Initialize a brand new SwiftUI Xcode project (target iOS 16.0+).
- **Core Integration**: Connect the previously developed SPM modules (`Home`, `DesignSystem`, `NetworkKit`) directly to the new project.
- **Modern Entry**: Replace the legacy `AppDelegate` with a pure SwiftUI `@main` entry point.

## Capabilities

### New Capabilities
- `app-shell`: The top-level application structure, including the entry point, global navigation (TabBar), and integration of feature modules.

## Impact

- **Architecture**: Transitions the project from a monolithic UIKit app to a modular, shell-first SwiftUI app.
- **Stability**: Eliminates all legacy symbol collisions and version mismatch errors.
- **Workflow**: All future development will occur in the new Target or within the `Packages/` directory.
