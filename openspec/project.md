# Project OpenSpec: HTZ iOS Modernization

## 1. Vision & Core Principles
This project aims to refactor the "黄庭禅" (HTZ) iOS application from a legacy UIKit/Singleton-heavy codebase into a modern, modular, and highly testable SwiftUI application using The Composable Architecture (TCA).

### Core Principles
- **Safety First**: The App must remain runnable at every phase.
- **Incrementalism**: Refactor one feature at a time; avoid "Big Bang" rewrites.
- **Modern Standards**: Target iOS 16+, Swift 5.9+, and SwiftUI 4.
- **Testability**: Every feature must be verifiable via unit tests (TCA TestStore).
- **Design Excellence**: Adhere to Apple's modern design language (Apple Music style).

## 2. Refactoring Goals
- **Architecture**: Transition to TCA for state management and SPM for modularity.
- **UI Framework**: Complete migration from UIKit/SnapKit to SwiftUI.
- **Data Layer**: Replace HandyJSON/SwiftyJSON with Swift `Codable`.
- **Media Core**: HTZNext plays through `HTZAudio.AudioEngine` (`AVPlayer`, `@MainActor`). Legacy FreeStreamer stays only in the UIKit app until retired.
- **User Experience**: Implement Dark Mode, Dynamic Type, and high-fidelity animations.

## 3. Technical Constraints & Targets
- **Target OS**: iOS 16.0+
- **Primary Language**: Swift 5.9+
- **State Management**: The Composable Architecture (TCA) v1.10+
- **Reactive Framework**: Combine (Native)
- **Dependency Management**: CocoaPods (External) + SPM (Internal Modules)
- **Networking**: Moya + Codable
- **Persistence**: Core Data (Wrapped)

## 4. Non-Negotiable Capabilities (Preservation)
- **Audio Integrity**: Background playback, queue advance, seek/rate, and signed-URL streaming must stay reliable; do not regress offline local-file play.
- **Social Integration**: WeChat/QQ/Weibo login and sharing must remain fully functional.
- **Push Notifications**: JPush integration must be preserved.
- **Offline Access**: Download and cache management must not be broken during migration.

## 5. Definition of Done (DoD)
- Feature is 100% SwiftUI (except for unavoidable low-level bridges).
- Business logic is managed by TCA Reducers with associated unit tests.
- UI adheres to the `DesignSystem` token specifications.
- No memory leaks or performance regressions compared to legacy implementation.
- Zero warnings in target modules.
