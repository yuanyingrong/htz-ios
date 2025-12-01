# QWEN.md - htz-ios Project Context

## Project Overview

This is the iOS source code for the "黄庭禅" (Huáng Tíng Chán) application - a media-focused application related to Chan Buddhism. The app provides audio and video content related to Chan Buddhism teachings, meditation, and practices. It features social sharing capabilities, push notifications, and a comprehensive media playback system.

The project is written in Swift and uses CocoaPods for dependency management. The app follows a tab bar navigation structure with sections for Home, Albums, a central play button, Video, and Profile.

## Project Architecture

- **Core Language:** Swift 5
- **UI Framework:** UIKit with programmatic UI construction
- **Dependency Management:** CocoaPods
- **Architecture Pattern:** View Controller-based modules with reusable components

### Key Modules:
- `Home`: Main content feed and navigation
- `Album`: Audio/video album browsing
- `Play`: Media playback functionality
- `Profile`: User account and settings
- `LearnClassics`: Educational content related to Chan Buddhism
- `Login`: Authentication system
- `Common`: Shared utilities and base classes

### Directory Structure:
- `htz/htz/`: Main source code
- `htz/htz/Class/`: Feature modules (Home, Album, Play, etc.)
- `htz/htz/Utils/`: Utility classes and managers
- `htz/htz/Public/`: Reusable UI components
- `htz/htz/Support/`: Supporting files including macros
- `htz/htz/Resource/`: Static resources and configuration
- `htz/htz/Base.lproj/`: Localization files
- `htz/htz/Assets.xcassets/`: App assets and images

## Key Technologies & Dependencies

### UI & Layout:
- `SnapKit`: Auto Layout DSL for programmatic constraint creation
- `Kingfisher`: Image downloading and caching

### Networking & Data:
- `Moya`: Network abstraction layer built on Alamofire
- `SwiftyJSON`: JSON parsing
- `HandyJSON`: Model mapping

### Media Playback:
- `ZFPlayer`: Video player framework
- `FreeStreamer`: Audio streaming library
- `IJKMediaFramework`: Media player framework
- AVFoundation: Apple's native media framework

### Social & Push:
- `JPush`: Push notification service
- `JShare`: Social sharing functionality
- `Weibo_SDK`: Sina Weibo integration
- `WechatOpenSDK`: WeChat integration
- `TencentOpenAPI-Unofficial`: QQ integration

### Other:
- `MJRefresh`: Pull-to-refresh functionality
- `PYSearch`: Search interface
- `Core Data`: Local data persistence
- `Alamofire`: HTTP networking

## Building and Running

To build and run this project, you will need Xcode and CocoaPods installed:

1. **Install Dependencies:**
   ```bash
   cd /Users/muxueqiang/Developer/htz-ios/htz
   pod install --repo-update
   ```

2. **Open the Workspace:**
   Open the `htz.xcworkspace` file in Xcode (do not open the `.xcodeproj` file directly).

3. **Run the App:**
   Select a simulator or a connected device and click the "Run" button in Xcode.

### Additional Build Commands:
- Local build: `xcodebuild -workspace htz.xcworkspace -scheme htz -configuration Debug build`
- Run tests: `xcodebuild -workspace htz.xcworkspace -scheme htz -destination 'platform=iOS Simulator,name=iPhone 15' test`

## Development Conventions

### Coding Style:
- Use 4-space indentation and same-line braces
- Prefix shared types with `HTZ` (e.g., `HTZTabbarViewController`, `HTZLogConfig`)
- Properties and methods use camelCase
- Constants use SCREAMING_SNAKE_CASE and are stored in `Support/Macros`
- Prefer `final` for view controllers and view models
- Use `guard` for early exits
- Use SnapKit for layout constraints (`view.snp.makeConstraints { ... }`)
- Programmatic UI construction instead of Storyboards

### Testing:
- Unit tests in `htzTests` exercise managers, networking helpers, and view models
- UI tests in `htzUITests` drive onboarding, login, playback, and tab changes
- Test naming convention: `test<Action>When<Condition>`
- Use `expectation(description:)` and `waitForExpectations` for async behavior

### File Organization:
- Feature modules organized in the `Class` directory
- Base view/view-model scaffolding in `Base`
- Reusable UI components in `Public`
- Constants and macros in `Support/Macros`
- Assets in `Assets.xcassets`
- Localized strings in `Base.lproj`

## Special Features

### Media Playback:
- Supports both audio and video playback with background play capabilities
- Uses multiple media frameworks to support various formats
- Has a global play button that appears when media is available

### Social Integration:
- Integrated with WeChat, Weibo, and QQ for sharing functionality
- OAuth login capabilities through multiple platforms

### Push Notifications:
- Integrates with JPush for push notifications
- Handles badge clearing when entering foreground

### Network Monitoring:
- Implements network state monitoring to handle different connection types (WiFi, cellular, none)

## Security & Configuration Notes

- API keys, tokens, and sensitive data should be loaded through user-defined build settings or local `.xcconfig` files
- Simulator-only credentials should be wrapped in `#if targetEnvironment(simulator)` guards
- The app has background audio capability enabled in Info.plist