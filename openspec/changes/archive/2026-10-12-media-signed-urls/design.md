## Context

The backend service (`api-server`) transitioned from publicly accessible Alibaba Cloud OSS URLs to private OSS access to enforce asset protection and Xiaoetong payment/subscription permissions. As a result, raw asset URLs return `403 Forbidden` (`AccessDenied`).
The backend introduces two dedicated endpoints:
- `POST /get/sutra/cover_url`
- `POST /get/sutra/item/file_url`

Clients must obtain temporary signed URLs with expiration timestamps (default 3600 seconds) to download and play media.

## Goals / Non-Goals

**Goals:**
- Provide client-side models and `HTZAPI` routes for `/get/sutra/cover_url` and `/get/sutra/item/file_url`.
- Implement signed URL resolution before audio playback, handling trial items seamlessly and displaying clear access denial alerts for unpaid items (`90001 access denied`).
- Asynchronously resolve and cache signed cover URLs for albums to restore visual covers in `AlbumCardView`, `BannerCarouselView`, and `AlbumDetailView`.
- Maintain TCA and Swift Concurrency idioms throughout `NetworkKit`, `HomeFeature`, and `PlayerFeature`.

**Non-Goals:**
- In-app purchase or direct payment processing (purchases occur externally via WeChat / Xiaoetong).
- Offline asset caching to disk for expired signed URLs (scoped for future cache architecture).

## Decisions

### 1. Audio Signed URL Resolution in AlbumDetailFeature / PlayerFeature
- **Choice**: When a track row is tapped, `AlbumDetailFeature` dispatches an action `trackTapped(SutraItem)`. The effect requests `POST /get/sutra/item/file_url`. Upon success (`200 OK`), the signed audio URL is handed off to `playerStore.send(.play(item))`.
- **Alternative Considered**: Resolving all track URLs in bulk during album load. Rejected because signed URLs expire, bulk generation places unnecessary load on storage-server, and unpaid tracks would return 403 errors during initial load.
- **Handling Access Denied**: If `/get/sutra/item/file_url` returns `code: 90001` or `HTTP 403`, a user-facing toast/alert is displayed ("该内容为付费专栏，请订阅后收听").

### 2. Cover Signed URL Resolution Strategy
- **Choice**: Introduce a lightweight `MediaURLClient` or extend `HomeClient` to resolve cover URLs on demand with in-memory caching keyed by `sutra_id` + expiration timestamp.
- **Alternative Considered**: Blocking album list rendering until all covers are resolved. Rejected because it would introduce multi-request waterfall latency. Instead, albums display initial metadata with fallback placeholders while signed URLs resolve.

### 3. Error Handling and Token Injection
- **Choice**: Ensure `token` is continuously injected in `HTZAPI` headers for both endpoints as required by `api-server`'s `TokenAuthMiddleware`.

## Risks / Trade-offs

- **[Risk] URL Expiration during long playback session** → Mitigation: Default `expire_seconds` is 3600s (1 hour). AVPlayer streams buffer continuously once connected. For subsequent tracks, fresh signed URLs are fetched on track start.
- **[Risk] Rate Limiting or Extra Network Hop** → Mitigation: Cover URLs are cached in-memory so repeated viewings of the same album do not trigger additional network requests.
