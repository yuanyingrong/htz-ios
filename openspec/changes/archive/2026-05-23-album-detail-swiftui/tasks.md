## 1. Network & Integration

- [x] 1.1 Update `HTZAPI.swift` to ensure `items` case uses POST and correct JSON body parameters (`sutra_id`, `page_index`, `page_size`).
- [x] 1.2 Extend `HomeClient` with `getSutraItems(sutraId: String)` that handles OSS URL formatting.
- [x] 1.3 Add navigation actions and state to `HomeFeature` to support pushing the detail view.

## 2. Logic Layer (TCA)

- [x] 2.1 Create `AlbumDetailFeature.swift` with state for `Album` and `[SutraItem]`.
- [x] 2.2 Implement the item fetching effect in the `AlbumDetailFeature` reducer.

## 3. UI Components (Classical/Podcast Style)

- [x] 3.1 Create `SutraItemRowView.swift` with refined typography (numbers, titles, durations).
- [x] 3.2 Create `AlbumDetailHeaderView.swift` with a large scaling artwork and metadata.
- [x] 3.3 Create `AlbumDetailView.swift` and integrate the immersive background.

## 4. Animation & Polishing

- [x] 4.1 Implement scroll-offset tracking to drive the header scaling animation.
- [x] 4.2 Configure navigation bar material transitions.
- [x] 4.3 Verify visual consistency with the refreshed Home screen.
