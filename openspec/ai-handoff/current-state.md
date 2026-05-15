# Current State

## Summary
The project has just completed the **OpenSpec Architecture Initialization** phase. The blueprint for refactoring is defined, but implementation has not yet begun.

## Status Breakdown

### ✅ Completed (Architecture Design)
- [x] OpenSpec Project Vision (`project.md`).
- [x] Core Technical Specifications (`specs/`).
- [x] Initial Phase 1 Change Roadmap (`changes/`).
- [x] Architecture Decision Records (`decisions/ADR-xxx.md`).
- [x] AI Operational Handoff Framework (`ai-handoff/`).

### ❌ Uncompleted (Implementation)
- [ ] Swift Package Manager (SPM) Infrastructure setup.
- [ ] TCA (The Composable Architecture) integration.
- [ ] Design System Tokens implementation.
- [ ] Model migration to `Codable`.
- [ ] Audio Player Actor wrapper.
- [ ] Any SwiftUI page migration.

## Current Real Architecture
- **Language**: Swift 5 (Mixed with legacy patterns).
- **UI Framework**: 100% UIKit with SnapKit.
- **State Management**: Fragments of singletons and closure-based callbacks.
- **JSON Parsing**: `HandyJSON` and `SwiftyJSON`.
- **Audio**: `FreeStreamer` (Objective-C) with global shared instance.
- **Navigation**: Traditional `UITabBarController` and `UINavigationController`.

## Technical Debt (Legacy)
- **God Classes**: `HTZPlayViewController` (too much responsibility).
- **Singletons**: `HTZNetWorkManager`, `HTZPlayerManager`, `HTZDownloadManager`.
- **Mixing Styles**: Multiple JSON parsing libraries.
- **No Tests**: Zero unit or UI tests.

## ⛔ Strictly Prohibited Areas (DO NOT TOUCH)
- **Legacy Business Logic**: Do not modify existing logic in `htz/htz/Class/` unless explicitly requested.
- **Audio Core**: Do not modify `FreeStreamer` source code or headers.
- **Social SDKs**: Do not touch WeChat, QQ, or Weibo SDK integration logic.
- **Core Data Schema**: Do not change the existing model definitions.
