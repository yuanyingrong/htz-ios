## 1. Visual Foundation (DesignSystem)

- [x] 1.1 Add `ImmersiveBackgroundView.swift` to the `Home` module (or `DesignSystem` if reused).
- [x] 1.2 Implement the dynamic blur effect using `.blur(radius: 40)` and `AsyncImage`.

## 2. Card Component (Home Feature)

- [x] 2.1 Create `AlbumCardView.swift` in the `Home` module.
- [x] 2.2 Design the card to emphasize the artwork with the title and metadata below it.
- [x] 2.3 Ensure the card uses `HTZRadius.md` and appropriate typography tokens.

## 3. Layout Refresh (Home Feature)

- [x] 3.1 Update `HomeView.swift` to use the immersive background behind the main `ScrollView`.
- [x] 3.2 Replace the `LazyVStack` list with a `LazyVGrid` for the album section.
- [x] 3.3 Apply material backgrounds to the navigation bar using `.toolbarBackground`.

## 4. Polishing

- [x] 4.1 Add a subtle transition effect when the background image changes.
- [x] 4.2 Verify readability across Light and Dark modes.
- [x] 4.3 Test scrolling performance with the immersive blur active.
