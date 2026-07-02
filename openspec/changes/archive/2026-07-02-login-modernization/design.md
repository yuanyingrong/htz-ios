## Context

This design outlines the secure integration of WeChat OAuth login and Keychain storage within the modernized `HTZNext` SwiftUI/TCA structure. It is focused entirely on the real-device MVP, with stubbed/reserved support for simulator environments.

## Goals / Non-Goals

**Goals (MVP):**
- A SwiftUI-based `LoginView` gating the main application.
- A secure `KeychainHelper` class within `NetworkKit` to manage access tokens.
- Composable Architecture (TCA) state machine (`AuthFeature`) representing authenticated and unauthenticated states.
- Clean integration with WeChat iOS SDK to request OAuth codes.
- Dynamic Moya header injection using real tokens from Keychain.
- Synchronous upload of WeChat user profiles to `/api/v1/userinfo/add`.

**Non-Goals (Deferred):**
- Account registration or password recovery (legacy left-overs).
- Interactive mock panels for simulator logins (simulator will skip WeChat authorization or warn gracefully, without mock popup UI).
- Automated 401 token refresh/eviction logic.

## Decisions

### 1. Storage: Native Keychain Services API
We will write a standard Swift wrapper around `SecItemAdd`, `SecItemCopyMatching`, and `SecItemDelete` for securely storing the accessToken under the service identifier `cn.org.htz.next.auth`.
- **Rationale**: Storing access tokens in `UserDefaults` in plaintext is a security risk. A lightweight custom Keychain wrapper is safer and requires no external cocoapod dependencies. Profile details (nickname, avatar URL) can continue to reside in `UserDefaults` for easy access.

### 2. State Modeling: App Routing Gatekeeper
We will update `RootView` to conditionally render the content based on `AuthFeature.State`'s logged-in status.
- **Rationale**: Gating the entire `CustomTabView` at the root view prevents modules from performing unauthenticated API calls or loading views with empty states.
```swift
struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>

    var body: some View {
        Group {
            if store.authState.isLoggedIn {
                CustomTabView(...)
            } else {
                LoginView(store: store.scope(state: \.auth, action: \.auth))
            }
        }
    }
}
```

### 3. WeChat Integration: AppDelegate Bridge to TCA
WeChat SDK requires receiving callbacks in `WXApiDelegate.onResp(_:)`. We will implement a custom `WeChatClient` dependency:
- **Rationale**: Isolates the static Objective-C WeChat callback mechanism from the functional, predictable TCA state changes. The `AppDelegate` will catch the `openURL` action, delegate it to `WXApi`, and publish the resulting auth code through a TCA Action or a dependency channel.

### 4. API Request Sequence
The authentication sequence will execute sequentially:
1. Fetch code from WeChat SDK.
2. Exchange code for Token via `/post/login`.
3. Read the returned `unionid`.
4. Call `/api/v1/userinfo/add` to register/sync profile details.
5. Save the token to Keychain and set local state to `loggedIn`.

## Risks / Trade-offs

- **[Risk] WeChat SDK in Simulator** → **[Mitigation]** The app will gracefully display a "WeChat not installed" alert or log a warning on simulator execution. Simulator testing will be deferred to phase 2 or rely on pre-inserted tokens during compilation for debugging.
- **[Risk] Sync API Failure** → **[Mitigation]** If `/api/v1/userinfo/add` fails, we will display an error message and refuse to log the user in, aligning with the legacy app's dependency on complete user profile records.

## Local Development Signing Bypass

To allow developers to compile and test on real devices using a Personal Free Developer Account (which does not support the Associated Domains capability and cannot register the official bundle ID), a temporary signing bypass is configured for local development.

### Local Development Configuration (Current):
- **Development Team**: `934KKYZ9Q2` (YingRong Yuan - Personal Team)
- **Bundle Identifier**: `cn.org.htz.next.HTZNext`
- **Entitlements**: `HTZNext.entitlements` is kept empty (Associated Domains disabled).

### Production Release Checklist (To Restore WeChat OAuth):
Before packaging the App Store release or conducting final WeChat integration tests on a company-provisioned device:
1. Change **Development Team** back to `QCGC77U855` (Paid Company Team).
2. Change **Bundle Identifier** back to `cn.org.htz` (to match WeChat Open Platform registry).
3. Re-add the Associated Domains entitlement to `HTZNext.entitlements`:
   ```xml
   <key>com.apple.developer.associated-domains</key>
   <array>
       <string>applinks:app.neixinchan.com:9500</string>
   </array>
   ```

