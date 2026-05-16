# Design System Specification

## Target State
A unified design system based on Apple's modern visual language (Apple Music style), implemented using design tokens and reusable SwiftUI components.

### 1. Design Tokens
- **Colors**: Named semantic colors supporting Dark Mode (htzAccent, htzBackground, htzLabel, etc.).
  - **Requirement**: The DesignSystem module SHALL provide semantic color tokens that support both Light and Dark modes.
  - **Scenario: Accessing a semantic color**
    - **WHEN** a view requests `Color.htzAccent`
    - **THEN** the system returns the correct accent color based on the current user interface style.
- **Typography**: Responsive font styles using SF Pro and SF Pro Rounded (htzLargeTitle, htzBody, htzLyric, etc.).
  - **Requirement**: The DesignSystem module SHALL provide standard typography styles using SF Pro and SF Pro Rounded fonts.
  - **Scenario: Applying a title style**
    - **WHEN** a view applies the `htzTitle` font style
    - **THEN** the text is rendered with the correct weight, size, and design (Rounded) as defined in the specification.
- **Spacing & Radius**: Standardized grid and corner values.
  - **Spacing**: Fixed-scale grid system (xs: 4pt, sm: 8pt, md: 16pt, etc.).
  - **Radius**: Consistent corner radii (sm: 8pt, md: 12pt, lg: 16pt, xl: 24pt).
  - **Requirement**: The DesignSystem module SHALL provide a standardized set of spacing and corner radius values.
  - **Scenario: Applying consistent padding**
    - **WHEN** a view uses `HTZSpacing.md`
    - **THEN** it applies exactly 16pt of spacing as defined in the layout grid.

### 2. Visual Language
- **Materials**: Extensive use of SwiftUI `.ultraThinMaterial` and `.regularMaterial` for blurs.
- **Iconography**: 100% migration to SF Symbols with hierarchical or multicolor rendering.
- **Shadows**: Soft, diffused shadows (low opacity) or no shadows (rely on depth/materials).
- **Motion**: High-quality spring animations for all transitions (`.spring(response: 0.4, dampingFraction: 0.8)`).

### 3. Core Components
- **Player Card**: Dynamic cover art with scale animation (1.0 when playing, 0.92 when paused).
- **Dynamic Background**: Full-screen blurred background using colors extracted from current album art.
- **Lyric Component**: Smoothly scrolling lyrics with current line highlighting and scaling.
- **Global Now Playing Bar**: A persistent, compact bar with a progress line and basic controls.

### 4. Accessibility
- Full support for **Dynamic Type** (all layouts must respond to font size changes).
- **Dark Mode** support by default using semantic colors.
- Proper accessibility labels for all interactive elements.
