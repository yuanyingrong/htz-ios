## 1. Directory Restructuring

- [ ] 1.1 Move the `htz/` directory (and its contents) to `legacy-app/`.
- [ ] 1.2 Remove the legacy `htz.xcworkspace` and `htz.xcodeproj` from the root (since they will now live in `legacy-app/`).

## 2. New App Initialization

- [ ] 2.1 Initialize a new SwiftUI project structure in a directory named `HTZApp/`.
- [ ] 2.2 Create `HTZApp.swift` with the `@main` entry point.
- [ ] 2.3 Create `RootView.swift` with a `TabView` structure.

## 3. Integration

- [ ] 3.1 Link the `HTZPackages` (local SPM package) to the new `HTZApp` target.
- [ ] 3.2 Add necessary Tab Bar icons (Home, Album, Profile) from the legacy assets.

## 4. Verification

- [ ] 4.1 Build and launch the App.
- [ ] 4.2 Verify the App starts directly into the modern SwiftUI `HomeView`.
- [ ] 4.3 Confirm the `htz` (Legacy) code is no longer being compiled.
