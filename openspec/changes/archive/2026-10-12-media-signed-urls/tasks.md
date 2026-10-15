## 1. Network Layer (NetworkKit)

- [x] 1.1 Add `SutraCoverURLResponse` and `SutraItemFileURLResponse` Codable models to `NetworkKit`.
- [x] 1.2 Add `sutraCoverURL(sutraId: String, expireSeconds: Int?)` and `sutraItemFileURL(sutraId: String, sutraItemId: String, expireSeconds: Int?)` cases to `HTZAPI`.
- [x] 1.3 Add corresponding client methods to `HomeClient` / `NetworkManager` for requesting signed cover and item URLs.
- [x] 1.4 Handle `90001 access denied` as a distinct `NetworkError.accessDenied` error case in `NetworkKit`.

## 2. Audio Playback Integration (Home & AlbumDetailFeature)

- [x] 2.1 Update `AlbumDetailFeature` state and actions to handle `trackTapped(SutraItem)` asynchronously.
- [x] 2.2 In `AlbumDetailFeature`, call `homeClient.getSutraItemFileURL` to obtain `signed_urls["audio"]`.
- [x] 2.3 On `accessDenied` (code 90001), present a user alert ("该内容为付费专栏，请订阅后收听") and do not send play action.
- [x] 2.4 On successful resolution, dispatch `.play` to `PlayerFeature` using the resolved signed audio URL.

## 3. Cover Image Signed URL Integration (Home & DesignSystem)

- [x] 3.1 Implement on-demand cover signed URL resolution with an in-memory cache in `HomeClient`.
- [x] 3.2 Update `AlbumDetailHeaderView` and `AlbumCardView` to consume resolved signed cover URLs.

## 4. Verification & Testing

- [x] 4.1 Write unit tests for `HTZAPI` cover and item signed URL requests and response decoding.
- [x] 4.2 Verify trial item (`is_trial = 1`) plays smoothly with audio output on iOS Simulator.
- [x] 4.3 Verify unpurchased paid item (`is_trial = 0`) correctly triggers the access denial alert.
- [x] 4.4 Verify album cover and banner images render correctly using signed URLs.

