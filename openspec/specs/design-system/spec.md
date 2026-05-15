# Design System Specification

## Target State
A unified design system based on Apple's modern visual language (Apple Music style), implemented using design tokens and reusable SwiftUI components.

### 1. Design Tokens
- **Colors**: Named semantic colors supporting Dark Mode (htzAccent, htzBackground, htzLabel, etc.).
- **Typography**: Responsive font styles using SF Pro and SF Pro Rounded (htzLargeTitle, htzBody, htzLyric, etc.).
- **Spacing**: Fixed-scale grid system (xs: 4pt, sm: 8pt, md: 16pt, etc.).
- **Radius**: Consistent corner radii (sm: 8pt, md: 12pt, lg: 16pt, xl: 24pt).

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
