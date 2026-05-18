## ADDED Requirements

### Requirement: SwiftUI @main Entry Point
The application SHALL use the modern Swift `@main` entry point with a struct conforming to the `App` protocol.

#### Scenario: Application Startup
- **WHEN** the application is launched
- **THEN** it SHALL initialize the `App` struct
- **AND** present the `RootView` as its initial window content.

### Requirement: Unified Modular Integration
The main App Target SHALL act as a lightweight shell that imports and integrates business features from the `Packages/` directory.

#### Scenario: Displaying Home Screen
- **WHEN** the App starts
- **THEN** it SHALL instantiate the `HomeView` from the `Home` package
- **AND** provide it with a correctly configured TCA `Store`.

### Requirement: Apple Music Style Global Navigation
The app SHALL implement a global `TabView` (TabBar) that follows Apple Music's design patterns, including support for a persistent "Now Playing" bar overlay in the future.

#### Scenario: Switching Tabs
- **WHEN** the user taps a TabBar item
- **THEN** the system SHALL switch to the corresponding feature view (e.g., Home, Album, Profile)
- **AND** maintain the navigation state of each tab.

### Requirement: High-Version Target
The project SHALL be configured with a minimum deployment target of iOS 16.0 to support modern SwiftUI and TCA features.

#### Scenario: Build Environment
- **WHEN** the project is compiled
- **THEN** it MUST use the iOS 16.0 SDK or newer
- **AND** require zero legacy bridging headers or CocoaPods dependencies.
