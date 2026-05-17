# Proposal: NetworkKit & Codable Migration

## Goal
Replace `HandyJSON` and `SwiftyJSON` with native `Codable` and unify network requests under a new `NetworkKit` module.

## Change
- Create `NetworkKit` module.
- Define `AudioTrack`, `Album`, `Banner` models as `Codable` structs.
- Implement a `NetworkManager` using Moya that returns `Codable` results.
