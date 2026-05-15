# Architecture Specification

## Target State
The application shall be structured as a modular system using Swift Package Manager (SPM) for internal business logic and The Composable Architecture (TCA) for state management.

### 1. Modularity (SPM)
- **App Layer**: Entry point, assembly of features, and global navigation.
- **Packages/Features**: Domain-specific UI and logic (Home, Album, Player, etc.).
- **Packages/CoreAudio**: Audio engine and queue management.
- **Packages/DesignSystem**: Shared UI components and tokens.
- **Packages/NetworkKit**: Unified networking layer (Moya + Codable).
- **Packages/CoreData**: Persistence services.

### 2. State Management (TCA)
- Every feature must implement `Reducer`, `State`, and `Action`.
- Dependencies must be registered via `DependencyKey` and injected into Reducers.
- Data flow must be strictly unidirectional (Action -> Reducer -> State -> View).
- Shared state (e.g., Now Playing) shall be propagated using TCA's state sharing mechanisms.

### 3. Data Flow & Communication
- **Networking**: All models must implement `Codable`. Legacy `HandyJSON` and `SwiftyJSON` are strictly prohibited in the target state.
- **Reactive**: Use `Combine` and `Async/Await` for asynchronous operations.
- **Navigation**: Use SwiftUI `NavigationStack` managed by TCA state.

### 4. Dependency Injection
- Use TCA's `@Dependency` system to decouple features from side-effects (Network, AudioPlayer, LocalStorage).
- Provide `liveValue` for production and `testValue`/`previewValue` for isolation.
