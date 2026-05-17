## ADDED Requirements

### Requirement: Unified Codable Models
The NetworkKit module SHALL define all data models (Album, SutraItem, Banner, etc.) as Swift `Codable` structs instead of `HandyJSON` or `NSObject` classes.

#### Scenario: Decoding an Album
- **WHEN** a JSON response containing album data is received
- **THEN** the `NetworkManager` SHALL decode it into an `Album` struct using `JSONDecoder`
- **AND** it MUST correctly map snake_case keys (e.g., `sutra_id`) to camelCase properties if applicable.

### Requirement: Moya Integration with Codable
The `NetworkManager` SHALL use `Moya` for networking and provide a generic method to perform requests that return `Codable` results.

#### Scenario: Performing a network request
- **WHEN** a feature requests data from a specific API endpoint
- **THEN** the `NetworkManager` SHALL execute the request via Moya
- **AND** return a `Result<T, Error>` where `T` is a `Codable` type.

### Requirement: Removal of HandyJSON/SwiftyJSON
New code in the `NetworkKit` and modern features SHALL NOT use `HandyJSON` or `SwiftyJSON`.

#### Scenario: Verifying new module dependencies
- **WHEN** the `NetworkKit` module is compiled
- **THEN** it MUST NOT have a dependency on `HandyJSON` or `SwiftyJSON`.
