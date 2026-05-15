# Next Priority

## Immediate Goal
The next step is to establish the **Modern Infrastructure (Phase 1, Step 1)**.

## Active Change
- **ID**: `01-infrastructure-setup`
- **Location**: `openspec/changes/01-infrastructure-setup/`

## Objective
Create the `Packages/` directory and initialize the `Package.swift` manifest with TCA dependencies.

## Why this one?
This is a prerequisite for all subsequent refactoring steps. We cannot implement the Design System or new Features without the modular SPM infrastructure and the TCA framework in place.

## Success Criteria
1. `Packages/` folder exists.
2. `Package.swift` is valid and includes TCA.
3. The project compiles with the new SPM dependency.
4. No legacy business code has been modified.
