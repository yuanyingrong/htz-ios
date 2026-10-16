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
The app SHALL show three tabs named 首页, 专辑, and 我的, and host the now-playing bar above the tab bar.

#### Scenario: Switching tabs
- **WHEN** the user selects a tab
- **THEN** the app SHALL show the home, album list, or profile feature for that tab
- **AND** the now-playing bar SHALL stay visible when a track is loaded.

### Requirement: Now Playing Opens Full Player
The now-playing bar SHALL open the full-screen player.

#### Scenario: Tap the bar
- **WHEN** the user taps the now-playing bar
- **THEN** the full-screen player sheet SHALL be presented
- **AND** dismissing it SHALL leave playback unchanged.

### Requirement: High-Version Target
The project SHALL be configured with a minimum deployment target of iOS 16.0 to support modern SwiftUI and TCA features.

#### Scenario: Build Environment
- **WHEN** the project is compiled
- **THEN** it MUST use the iOS 16.0 SDK or newer
- **AND** require zero legacy bridging headers or CocoaPods dependencies.
