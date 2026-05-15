# Design: Infrastructure Setup

## Directory Structure
```text
htz/
├── Packages/
│   ├── Package.swift (Manifest)
│   ├── Features/ (Home, Album, etc.)
│   ├── CoreAudio/
│   ├── DesignSystem/
│   ├── NetworkKit/
│   └── SharedModels/
```

## Integration Strategy
- **CocoaPods**: Continue using for external SDKs (JPush, JShare, FreeStreamer).
- **SPM**: Use for all new internal business logic and UI components.
- **Bridging**: Ensure SPM modules can be imported by the main Xcode project.

## Dependency Management
Add `swift-composable-architecture` to the SPM manifest.
