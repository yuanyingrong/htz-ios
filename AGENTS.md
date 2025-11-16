# Repository Guidelines

## Project Structure & Module Organization
Open `htz.xcworkspace` so CocoaPods resolves correctly. Core source lives in `htz/htz`: `Base` supplies reusable view/view-model scaffolding, `Class/<Feature>` hosts the Home, Login, Play, Album, Profile, and LearnClassics modules, `Utils` provides helpers/loggers/managers, and `Support/Macros` centralizes constants. Assets, localized strings, and tab icons reside in `Assets.xcassets`, `Base.lproj`, and `Resource/TabBar`, while reusable UI components sit in `Public`. Tests are split into `htz/htzTests` (logic) and `htz/htzUITests` (flows).

## Build, Test, and Development Commands
- `pod install --repo-update` - install or refresh Pods whenever the `Podfile` or Xcode version changes.
- `xcodebuild -workspace htz.xcworkspace -scheme htz -configuration Debug build` - reproducible local build; swap `Release` when preparing an archive.
- `xcodebuild -workspace htz.xcworkspace -scheme htz -destination 'platform=iOS Simulator,name=iPhone 15' test` - run unit and UI suites; pass `-only-testing:htzTests/<Case>` to focus.
- `open htz.xcworkspace` - launch Xcode with the workspace instead of the project file.

## Coding Style & Naming Conventions
Use Swift 5 with 4-space indentation and same-line braces (see `htz/htz/AppDelegate.swift:1`). Prefix shared types with `HTZ` (`HTZTabbarViewController`, `HTZLogConfig`), keep properties/methods camelCase, and reserve SCREAMING_SNAKE_CASE for constants stored in `Support/Macros`. Prefer `final` for view controllers and view models, `guard` for early exits, dependency injection over globals, and SnapKit for layout (`palyButton.snp.makeConstraints { ... }`). Localized strings live in `Base.lproj`. No repo-level linter exists; rely on Xcode warnings or your local formatter before pushing.

## Testing Guidelines
`XCTestCase` in `htzTests` should exercise managers, networking helpers, and view models; `XCUITest` in `htzUITests` drives onboarding, login, playback, and tab changes. Name tests `test<Action>When<Condition>` and cover both success and failure paths. Wrap async behavior in `expectation(description:)`/`waitForExpectations`, especially around AVFoundation or notification observers. Run the simulator command above before every push and isolate flakes with `-only-testing`.

## Commit & Pull Request Guidelines
Commits follow `<Type>: <imperative>` (e.g., `Feat: add log`, `Update Podfile`); keep scope tight and mention Pod or asset updates in the body. PRs need an intent summary, linked issue, screenshots for UI, notes on data migration or login resets, and confirmation that `pod install` plus `xcodebuild ... test` were executed successfully.

## Configuration & Security Tips
Push, share, and playback wiring resides in `AppDelegate+Push.swift` and `AppDelegate+Share.swift`. Load API keys, tokens, and Union IDs through user-defined build settings or local `.xcconfig` files instead of source control, and wrap simulator-only credentials inside `#if targetEnvironment(simulator)` guards as demonstrated in `AppDelegate.swift`. After raising the Xcode or iOS deployment target, clean DerivedData and rerun `pod install`.
