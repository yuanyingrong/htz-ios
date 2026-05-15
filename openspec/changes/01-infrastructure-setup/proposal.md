# Proposal: Infrastructure Setup (Skeleton)

## Problem
The current project is a monolithic UIKit app using CocoaPods only. To enable modern refactoring, we need a modular structure and a modern state management framework.

## Proposed Change
- Create a `Packages/` directory for internal Swift Package Manager (SPM) modules.
- Initialize the SPM structure with a root `Package.swift`.
- Integrate `The Composable Architecture` (TCA) as the primary state management framework.
- Establish skeleton (empty) modules for `DesignSystem`, `NetworkKit`, and `CoreAudio` to define the modular architecture.

## Expected Impact
- Enables modular development.
- Prepares the workspace for TCA-based features.
- **Zero impact** on existing UIKit code and App entry point.
- The App remains 100% UIKit-driven at the end of this change.
