## Context

The legacy App uses `HandyJSON` and `SwiftyJSON` for parsing network responses into `NSObject` based models. This approach is outdated, lacks compiler safety, and makes it difficult to use TCA or SwiftUI effectively. We need to unify our data layer using modern Swift `Codable`.

## Goals / Non-Goals

**Goals:**
- Establish the `NetworkKit` SPM module.
- Create `Codable` versions of core business models (Album, Track, Banner).
- Implement a `NetworkManager` wrapper for `Moya` that supports `Codable` decoding.
- Provide a clean API for modern features (TCA) to fetch data.

**Non-Goals:**
- Refactoring the entire App to use `NetworkKit` at once.
- Removing `HandyJSON` from the legacy project (it will coexist until all UIKit views are migrated).

## Decisions

- **Decision: Structs over Classes** → All new models will be `struct` types. Rationale: Value types are preferred in modern Swift for thread safety and local reasoning.
- **Decision: Moya as the base** → Continue using `Moya`. Rationale: It's already integrated and provides a solid abstraction for API endpoints. We will just add a `Codable` layer on top.
- **Decision: Custom JSONDecoder** → Centralize `JSONDecoder` configuration (e.g., `keyDecodingStrategy = .convertFromSnakeCase`). Rationale: Ensures consistent parsing across all models.

## Risks / Trade-offs

- **[Risk] Model Duplication** → We will have both legacy `HTZAlbumInfoModel` and new `Album` struct. Mitigation: Use clear naming conventions and keep them in different modules (`htz` target vs `NetworkKit` package).
- **[Risk] API Key/Configuration** → The legacy `HTZNetWorkManager` has hardcoded URLs and keys. Mitigation: Extract these into a configuration object within `NetworkKit`.
