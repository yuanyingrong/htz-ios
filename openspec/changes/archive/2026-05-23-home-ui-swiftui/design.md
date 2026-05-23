## Context

We have successfully implemented the `HomeFeature` (TCA logic) and `DesignSystem` (UI Tokens) as SPM modules. Currently, the legacy `HTZHomeViewController` is still handling its own networking and UI via SnapKit. We will now build the `HomeView` in SwiftUI to consume the new TCA logic and Design System tokens.

## Goals / Non-Goals

**Goals:**
- Create `HomeView.swift` in the `Home` SPM module using SwiftUI.
- Use `WithViewStore` (or Swift 5.9 observation if using TCA 1.7+) to bind to `HomeFeature.State`.
- Implement basic, modular subviews (`BannerView`, `AlbumRowView`).
- Load external images asynchronously (using `AsyncImage` or `Kingfisher` via SPM if needed, though native `AsyncImage` is preferred for simplicity if caching is not strictly required immediately).
- Create a bridge mechanism so the legacy app can present this view.

**Non-Goals:**
- Completely deleting `HTZHomeViewController` and routing in the main app (we will build the SwiftUI view and present it, but full navigation replacement comes later).
- Implementing deep playback logic when clicking an album (just navigating or printing a log is sufficient for now).

## Decisions

- **Decision: SwiftUI Observation** → We will use TCA's modern `@ObservableState` and `WithPerceptionTracking` (or native Swift 5.9 Observation) to bind state to the view, avoiding the older `WithViewStore` boilerplate.
- **Decision: Image Loading** → We will use native SwiftUI `AsyncImage` for MVP. Rationale: Avoids adding `Kingfisher` as an SPM dependency immediately, keeping the module lightweight. If caching becomes an issue, we will wrap `Kingfisher` later.
- **Decision: Layout** → Use `ScrollView` containing a `TabView` (for banners) and a `LazyVGrid` or `LazyVStack` (for albums). Rationale: Standard modern iOS layout patterns.

## Risks / Trade-offs

- **[Risk] UIKit Integration** → Presenting a pure SwiftUI page within a legacy `UITabBarController` might cause navigation bar issues. Mitigation: Wrap `HomeView` in a `UIHostingController` and carefully configure its lifecycle in a temporary bridge controller.
- **[Risk] Missing Assets** → Mock data images might fail to load. Mitigation: Add a placeholder view (using `Color.htzBackground`) while `AsyncImage` is loading.
