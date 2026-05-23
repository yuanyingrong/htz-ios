## Context

The `HTZNext` application now features an immersive, card-based home screen. To maintain visual continuity, the `AlbumDetailView` must transition from a simple list to a premium, media-centric experience. This design draws heavily from **Apple Music Classical** (for information density and clarity) and **Apple Podcasts** (for program-level metadata).

## Goals / Non-Goals

**Goals:**
- Implement a **Sticky Hero Header** that scales and blurs on scroll.
- Use **Immersive Backgrounds** that derive from the album's cover art.
- Refine the track list (Sutra Items) with **Classical-style typography** (prominent numbers, secondary metadata).
- Maintain 100% TCA compatibility for navigation and state.

**Non-Goals:**
- Full audio playback controls (to be handled in `audio-engine-v2`).
- Social features (comments/likes).

## Decisions

### 1. Header: The "Hero" Approach
The view will start with a large, high-resolution album cover. As the user scrolls, the cover will scale down and the background will transition into the navigation bar using `.ultraThinMaterial`.
- **Reference**: Apple Music / Apple TV.

### 2. Information Organization: The "Classical" Grid
Track information will include index numbering, title, and duration/status. We will use SF Pro Rounded and varying font weights to create a clear hierarchy.
- **Reference**: Apple Music Classical.

### 3. Background: Shared Immersive Logic
The `ImmersiveBackgroundView` will be utilized to provide a cohesive "halo" effect, ensuring that the transition from Home to Detail feels like a natural extension of the same space.

### 4. Navigation: Path-Based
We will use TCA's `Path` to push the `AlbumDetailFeature`. This allows us to pass the `Album` model directly and initiate the `/get/sutra/items` fetch immediately.

## Risks / Trade-offs

- **[Risk] Scroll Jitter** → **[Mitigation]** Use `CoordinateSpace` and `GeometryReader` carefully to calculate scroll offsets for the sticky header.
- **[Risk] Image Loading** → **[Mitigation]** Ensure `HomeClient` handles URL formatting (OSS prefix) consistently for both albums and items.
