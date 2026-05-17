## 1. Module Infrastructure

- [x] 1.1 Link `Moya` and `Combine` to the `NetworkKit` SPM module.
- [x] 1.2 Create `NetworkManager.swift` with basic `Codable` request support.

## 2. Core Models

- [x] 2.1 Implement `Album` Codable struct.
- [x] 2.2 Implement `SutraItem` (Track) Codable struct.
- [x] 2.3 Implement `Banner` Codable struct.

## 3. API Integration

- [x] 3.1 Define `HTZAPI` enum (Moya Target) within `NetworkKit`.
- [x] 3.2 Implement a sample endpoint (e.g., Get Album List) using the new architecture.

## 4. Verification

- [x] 4.1 Write a unit test to verify that a JSON string can be correctly decoded into the new `Album` struct.
- [x] 4.2 Verify that `NetworkKit` builds correctly without legacy dependencies.
