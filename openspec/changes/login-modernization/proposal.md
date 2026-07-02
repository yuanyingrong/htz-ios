## Why

The current `HTZNext` target uses a hardcoded developer Token in `AuthManager` to bypass authentication for API calls. To make the new SwiftUI-based app usable on real devices and ready for production, we need a complete, secure login flow using WeChat OAuth, integrated directly with the new TCA and SwiftUI architecture.

## What Changes

### MVP Scope (Phase 1):
- **WeChat Integration**: Register the existing WeChat AppID (`wx411fef9024bd3b5b`) in the new `HTZNext` target.
- **Keychain Storage**: Implement a secure credential manager inside the `NetworkKit` module to store and retrieve the Access Token in the Keychain, and non-sensitive user profile data in `UserDefaults`.
- **TCA Login Feature**: Build an `AuthFeature` module using Composable Architecture to manage login states (`loggedOut` and `loggedIn`).
- **Gatekeeping UI**: Add a SwiftUI-based `LoginView` that is displayed when the user is logged out, blocking access to `Home` and `Player` modules until authentication succeeds.
- **Token Injection**: Update `NetworkKit`'s HTTP Header injection to dynamically use the Keychain-stored Token.
- **API Flow**:
  1. Trigger WeChat OAuth request.
  2. Handle delegate callback in `AppDelegate` and pass the auth code to the TCA store.
  3. POST the authorization code to `/post/login` to obtain the Token.
  4. POST user profile details to `/api/v1/userinfo/add` to sync user data.
  5. Save Token to Keychain and transition state to `loggedIn`.

### Deferred to Phase 2:
- **Simulator / Developer Mock Mode**: Rich Mock UI / debug backdoors for simulator testing.
- **Auto-Logout on 401**: Global network interceptor for Token expiration and automatic logout.
- **Profile / Info Editing**: Profile edit, telephone binding, and other secondary features.

## Capabilities

### New Capabilities
- `auth-feature`: The core authentication state machine (TCA Reducer) and `LoginView` UI.
- `keychain-storage`: A helper service in `NetworkKit` for Keychain read/write/delete operations.

### Modified Capabilities
- `app-shell`: `RootView` will be updated to observe `AuthState` and switch between `LoginView` and the main `CustomTabView` app container.
- `network-kit`: Moya requests will dynamically inject the Token retrieved from the Keychain.

## Impact

- **Packages/NetworkKit**: Add Keychain helpers and update `AuthManager` to read/write from Keychain.
- **Packages/Features/Home**: Add login entry or support dynamic loading once logged in.
- **HTZNext/RootView**: Integrate gatekeeping condition on `AuthState`.
- **`htz` Legacy Project**: Unaffected.
