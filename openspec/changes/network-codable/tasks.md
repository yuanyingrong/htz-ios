## 1. Module Infrastructure

- [ ] 1.1 Link `Moya` and `Combine` to the `NetworkKit` SPM module.
- [ ] 1.2 Create `NetworkManager.swift` with basic `Codable` request support.

## 2. Core Models

- [ ] 2.1 Implement `Album` Codable struct.
- [ ] 2.2 Implement `SutraItem` (Track) Codable struct.
- [ ] 2.3 Implement `Banner` Codable struct.

## 3. API Integration

- [ ] 3.1 Define `HTZAPI` enum (Moya Target) within `NetworkKit`.
- [ ] 3.2 Implement a sample endpoint (e.g., Get Album List) using the new architecture.

## 4. Verification

- [ ] 4.1 Write a unit test to verify that a JSON string can be correctly decoded into the new `Album` struct.
- [ ] 4.2 Verify that `NetworkKit` builds correctly without legacy dependencies.
