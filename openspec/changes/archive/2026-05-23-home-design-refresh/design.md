## Context

The current `HomeView` is functional but visualy flat. We have integrated real data and valid tokens, so the foundation is solid. This design focuses on the aesthetic "shell" and content presentation, moving away from a monolithic list to a richer, card-based interface.

## Goals / Non-Goals

**Goals:**
- Transition from `AlbumRowView` (list) to `AlbumCardView` (grid/section).
- Introduce a dynamic background that subtly changes based on the top banner content.
- Ensure high information density remains readable (Classical reference).
- Use `LazyVGrid` for efficient rendering of card sections.

**Non-Goals:**
- Changes to underlying TCA logic or API endpoints.
- New features beyond visual presentation (e.g., search or filtering).

## Decisions

### 1. Layout: Two-Column Adaptive Grid
We will use `LazyVGrid` with `GridItem(.adaptive(minimum: 160))` for the "Recommended Albums" section.
- **Rationale**: Cards provide a much better canvas for artwork than rows, aligning with Apple Podcasts.

### 2. Immersive Layer: Background Blur
Implement an `ImmersiveBackgroundView` that takes an image URL and renders a full-screen, ultra-blurred version behind the content.
- **Rationale**: Creates a "halo" effect for the artwork, a hallmark of modern Apple TV and Music interfaces.

### 3. Navigation Styling: Material Overlays
Use `.toolbarBackground(.ultraThinMaterial, for: .navigationBar)` to ensure the navigation bar feels integrated into the immersive background.
- **Rationale**: Enhances the sense of depth and modernity.

### 4. Card Geometry
Cards will use `HTZRadius.md` (12pt) and `HTZSpacing.md` (16pt) for consistency. Typography will favor SF Pro Rounded to soften the interface.

## Risks / Trade-offs

- **[Risk] Background Performance** → **[Mitigation]** Use a low-resolution thumbnail for the blur or a heavy cache for the background image to avoid scroll lag.
- **[Risk] Information Density** → **[Mitigation]** Keep card titles short and use secondary captions for IDs/metadata to avoid clutter.
