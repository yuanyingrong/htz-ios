## ADDED Requirements

### Requirement: SwiftUI View Integration
The HomeFeature SHALL provide a SwiftUI `HomeView` that is initialized with a `StoreOf<HomeFeature>`.

#### Scenario: View Initialization
- **WHEN** the `HomeView` is instantiated
- **THEN** it SHALL accept a TCA `Store`
- **AND** it SHALL bind to the state and actions of that store.

### Requirement: Banner Carousel UI
The `HomeView` SHALL display a carousel of banners when `state.banners` is not empty.

#### Scenario: Rendering banners
- **WHEN** the state contains a list of banners
- **THEN** the UI SHALL render a horizontally scrollable area
- **AND** use `DesignSystem` tokens for spacing (`HTZSpacing.md`) and corner radius (`HTZRadius.md`) on banner images.

### Requirement: Album Grid UI
The `HomeView` SHALL display a grid or list of albums below the banners.

#### Scenario: Rendering albums
- **WHEN** the state contains a list of albums
- **THEN** the UI SHALL render an album list
- **AND** use `DesignSystem` typography tokens (e.g., `htzHeadline` for album titles) and colors (`htzLabel` for text).

### Requirement: Loading and Error States
The UI SHALL reflect the loading and error states defined in the `HomeFeature` logic.

#### Scenario: Displaying loading state
- **WHEN** `state.isLoading` is true
- **THEN** the UI SHALL display a `ProgressView` or loading indicator.

#### Scenario: Displaying error state
- **WHEN** `state.errorMessage` is present
- **THEN** the UI SHALL display the error text
- **AND** use the `htzLabel` color or an appropriate error semantic color if defined.
