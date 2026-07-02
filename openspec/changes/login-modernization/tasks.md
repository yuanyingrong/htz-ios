## 1. Project & SDK Configuration

- [ ] 1.1 Change the `HTZNext` target's Bundle Identifier to `cn.org.htz` to align with the WeChat console configuration.
- [ ] 1.2 Add URL Scheme (`wx411fef9024bd3b5b`) and Associated Domains (Universal Link `https://app.neixinchan.com:9500/`) to the `HTZNext` target.
- [ ] 1.3 Import/Link WeChat SDK headers in `HTZNext` bridging header.

## 2. Infrastructure & Storage (NetworkKit)

- [ ] 2.1 Create `KeychainHelper.swift` in the `NetworkKit` module to support saving, loading, and deleting String credentials.
- [ ] 2.2 Refactor `AuthManager.swift` to read and write token from/to Keychain instead of hardcoded strings.
- [ ] 2.3 Update `HTZAPI.swift` headers injection to retrieve token dynamically via `AuthManager.shared.token`.

## 3. Composable Architecture: Auth & Navigation

- [ ] 3.1 Declare a new target `AuthFeature` in `Packages/Package.swift`.
- [ ] 3.2 Create `AuthFeature.swift` defining state, actions, and reducer (including `wechatLoginTapped`, `authCodeReceived`, `syncCompleted`).
- [ ] 3.3 Create a clean `LoginView.swift` in SwiftUI using `DesignSystem` colors and a "微信登录" (WeChat Login) button.
- [ ] 3.4 In `AppDelegate` (or App entry point), set up `WXApiDelegate` callback routing to forward authorization codes to the `AuthFeature` store.
- [ ] 3.5 Update `RootView.swift` to observe `AuthState` and switch conditionally between `LoginView` and the tab-based main app view.

## 4. Testing & Verification

- [ ] 4.1 Write unit tests for `KeychainHelper` verifying credential lifecycle.
- [ ] 4.2 Write unit tests for `AuthFeature` reducer, validating state transitions from `loggedOut` to `loggedIn` upon receiving a successful token and sync code.
- [ ] 4.3 Verify real-device WeChat authorization redirection and successful API token injection.
