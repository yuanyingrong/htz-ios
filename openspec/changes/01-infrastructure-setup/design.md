# Design: Infrastructure Setup (Skeleton)

## Directory Structure
```text
htz/
├── Packages/
│   ├── Package.swift (Manifest)
│   ├── CoreAudio/        # Empty module skeleton
│   ├── DesignSystem/     # Empty module skeleton
│   └── NetworkKit/       # Empty module skeleton
```

## Integration Strategy
- **CocoaPods**: Unchanged. Continues to handle all legacy external SDKs.
- **SPM**: Root `Package.swift` added to the Xcode Workspace.
- **Coexistence**: The existing UIKit App target will link against the new SPM packages, but won't use them yet.

## Dependency Management
- **TCA**: Added as a dependency in `Package.swift` to make it available for future modules.
- **Internal Dependencies**: `NetworkKit` and `CoreAudio` will eventually be dependencies for Feature modules.
