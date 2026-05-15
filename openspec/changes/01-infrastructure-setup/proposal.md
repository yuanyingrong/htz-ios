# Proposal: Infrastructure Setup

## Problem
The current project is a monolithic UIKit app using CocoaPods only. To enable modern refactoring, we need a modular structure and a modern state management framework.

## Proposed Change
- Create a `Packages/` directory for internal Swift Package Manager (SPM) modules.
- Initialize the SPM structure with a root `Package.swift`.
- Integrate `The Composable Architecture` (TCA) as the primary state management framework.
- Prepare the ground for a SwiftUI `@main` entry point while maintaining the legacy `AppDelegate` for compatibility.

## Expected Impact
- Enables modular development.
- Allows using TCA in new/refactored features.
- No immediate impact on existing UIKit code (side-by-side coexistence).
