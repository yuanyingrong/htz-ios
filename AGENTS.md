# Repository Guidelines

## What this is
黄庭禅 iOS：双轨仓库。现役开发面是 **HTZNext**（SwiftUI + TCA + SPM）。`htz/` 是 CocoaPods UIKit 遗留工程，仅在修线上兼容或对照行为时改动。Android 对照仓在 sibling：`../htz-android-ref`。

## How to run
- **HTZNext（默认）**：`open HTZNext/HTZNext.xcodeproj`，scheme `HTZNext`。
  - Build：`xcodebuild -project HTZNext/HTZNext.xcodeproj -scheme HTZNext -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build`
  - Package tests：`cd Packages && xcodebuild test -scheme HTZPackages-Package -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:HomeTests -only-testing:PlayerFeatureTests`
  - 模拟器名以本机 `xcodebuild -showdestinations` 为准（常见 iPhone 17 / OS 26.x）。
- **Legacy**：`cd htz && pod install`，再 `open htz/htz.xcworkspace`，scheme `htz`。

## Stack
- HTZNext：Swift 5.9+ / iOS 16+ / SwiftUI / TCA / SPM（`Packages/`：NetworkKit、HTZAudio、PlayerFeature、Home、Auth、DesignSystem）
- Playback：`HTZAudio.AudioEngine`（`@MainActor` + `AVPlayer`）；TCA 经 `\.playerClient`、`\.playback`（`PlayerRelay`）
- Downloads：`\.downloads` / `DownloadCenter`；网络：`\.library` → `LibraryAPI`
- Share：`\.shareClient`（`ShareClient`）；微信 SDK 只在 app target、真机分支注入（`#if !targetEnvironment(simulator)`）
- Dialogs：清空/退出等用 `htzConfirmSheet`；居中付费弹窗用 `htzCenterDialog`（勿再加系统 `confirmationDialog`/`alert` 做同类确认）
- Legacy：UIKit + CocoaPods + SnapKit；类型前缀 `HTZ`

## Layout & conventions
- App shell：`HTZNext/HTZNext/`（`RootView` 用 `@ComposableArchitecture.Bindable` + `.sending` 绑 `showFullPlayer`）
- Features：`Packages/Features/{Home,Player,Auth}/`；「我的」在 `Home/Profile/`
- Shared：`Packages/{NetworkKit,HTZAudio,DesignSystem}/`；Android 对照图标在 `DesignSystem/.../Images.xcassets`（`HTZImage`）
- OpenSpec：`openspec/`；提交：`<Type>: <imperative>`。密钥走 xcconfig，模拟器样例凭据包在 `#if targetEnvironment(simulator)`。
- 播放：点上一集/下一集**始终按列表顺序**；随机模式只在**播完自动切歌**时生效；切歌失败须恢复上一集。

## Current status (2026-10-18)
- 分支 `feature/rf-zhihao`：相对 `origin` 有大量**未提交**改动（Android UI 对齐：首页/专辑行/播放列表/睡眠定时/倍速与分享 sheet、反馈含视频、确认弹窗与付费居中弹窗；播放器切歌/Perception；下载图标统一等），待 review / 提交。
- 主机：`http://app.htzchina.org:9100`。本机若开 fake-IP 代理导致 9100 超时，需直连该域名。
- 已知未验收：微信分享（模拟器无微信；SDK 仅真机）；反馈 `image_urls` 已改为 Android 同款 JSON 数组字符串，未对真实服务端回归；手机号登录未对真实服务端验收；模拟器 Keychain 相关测试在更早 HEAD 上即失败。
- 活动变更：`openspec/changes/audio-engine-v2`（MVP 完成；残留 UI/手动验证 4.5–4.7；tasks 里仍写 `Actor`，以代码 `@MainActor` 为准）。
