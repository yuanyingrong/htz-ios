# SwiftUI Migration Specification

## Target State
The application shall be 100% SwiftUI (for the UI layer), utilizing iOS 16+ features like `NavigationStack` and `TabView` with custom styling.

### 1. Migration Strategy
- **Outside-In vs. Inside-Out**: Generally "Inside-Out" (leaf pages first) to minimize navigation complexity during transition.
- **Interoperability**: Use `UIViewControllerRepresentable` to bridge legacy UIKit pages into the new SwiftUI shell temporarily.
- **Entry Point**: The App must transition to `@main` and a `RootView` using `AppFeature` (TCA).

### 2. Navigation Architecture
- **Root**: `TabView` with system-styled tabs but custom overlays (Now Playing Bar).
- **Stacks**: Each tab maintains its own `NavigationStack` managed by TCA state.
- **Deep Linking**: Type-safe navigation destinations using TCA's navigation system.

### 3. Component Replacement
- **UITableView/UICollectionView** -> `List`, `LazyVStack`, `LazyVGrid`.
- **MJRefresh** -> Native `.refreshable`.
- **PYSearch** -> Native `.searchable`.
- **SnapKit** -> SwiftUI layout primitives (`VStack`, `HStack`, `ZStack`, `padding`, `frame`).

### 4. Transition Order (Priority)
1. **Profile**: Simple state, low risk.
2. **Search/Login**: Decoupled features.
3. **Album List**: Grid/List transition.
4. **Home**: High complexity layout.
5. **Player**: Most critical page, high-fidelity requirement.
6. **Navigation/TabBar**: Final unification.
