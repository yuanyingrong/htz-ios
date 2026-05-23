## 1. Setup

- [x] 1.1 Update `Packages/Package.swift` to add `DesignSystem` as a dependency to the `Home` target.

## 2. Core UI Components

- [x] 2.1 Create `BannerCarouselView.swift` inside the `Home` module.
- [x] 2.2 Create `AlbumRowView.swift` inside the `Home` module.
- [x] 2.3 Create `HomeView.swift` and integrate `BannerCarouselView` and `AlbumRowView`.

## 3. State Binding and Lifecycle

- [x] 3.1 Bind `HomeView` to `StoreOf<HomeFeature>`.
- [x] 3.2 Ensure `HomeView` handles `isLoading` and `errorMessage` states visually.
- [x] 3.3 Trigger `.onAppear` action when `HomeView` appears.

## 4. Integration Bridge

- [x] 4.1 Create `HomeBridgeViewController.swift` in the main `htz` target that wraps `HomeView` in a `UIHostingController`.
