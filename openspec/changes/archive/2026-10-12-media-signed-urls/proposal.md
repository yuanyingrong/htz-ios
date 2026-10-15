## Why

The backend media storage (`htz-sutra` OSS bucket) has been switched to private access to protect audio assets and enforce Xiaoetong subscription permissions. Direct access to raw OSS URLs now returns `403 AccessDenied`.
Clients must now obtain temporary signed URLs for album cover images (`POST /get/sutra/cover_url`) and audio/lyric streams (`POST /get/sutra/item/file_url`). This change modernizes media resource resolution across HTZNext, enabling successful cover display, trial playback, and proper permission gating for paid content.

## What Changes

- **Cover Image Signed URL Resolution**: Request temporary signed URLs via `/get/sutra/cover_url` and cache them in-memory to prevent redundant API calls.
- **Audio Playback Signed URL Resolution**: Before starting playback, retrieve signed URLs for audio and lyric files via `/get/sutra/item/file_url`.
- **Paywall / Access Denial Handling**: Gracefully handle `90001 access denied` responses when unpurchased paid items are tapped, informing the user instead of failing silently or crashing.
- **NetworkKit API Endpoints**: Add `sutraCoverURL` and `sutraItemFileURL` targets to `HTZAPI`.

## Capabilities

### Modified Capabilities
- `network-kit`: Add API endpoints and response models for `/get/sutra/cover_url` and `/get/sutra/item/file_url`.
- `album-detail`: Update audio playback trigger to resolve signed URLs asynchronously prior to sending to `AudioEngine`.
- `player`: Support playing audio with signed URLs and handling URL resolution errors / permission denials.

## Impact

- `NetworkKit`: Extended with new `HTZAPI` cases and `SignedMediaResponse` models.
- `Home` / `AlbumDetailFeature`: Reducer and client will request signed audio URLs before playback.
- `HTZAudio` / `PlayerFeature`: Will consume pre-signed audio URLs directly into `AVPlayerItem`.
