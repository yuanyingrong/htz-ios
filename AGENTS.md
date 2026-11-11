# Repository Guidelines

## What this is
黄庭禅 iOS：双轨仓库。现役开发面是 **HTZNext**（SwiftUI + TCA + SPM）。`htz/` 是 CocoaPods UIKit 遗留工程，仅在修线上兼容或对照行为时改动。Android 对照仓在 sibling：`../htz-android-ref`。

## How to run
- **HTZNext（默认）**：`open HTZNext/HTZNext.xcodeproj`，scheme `HTZNext`。
  - Build：`xcodebuild -project HTZNext/HTZNext.xcodeproj -scheme HTZNext -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build`
  - Package tests：`cd Packages && xcodebuild test -scheme HTZPackages-Package -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:HomeTests -only-testing:PlayerFeatureTests`
  - CI：`.github/workflows/package-tests.yml` 在 `master` 推送和 pull request 上只跑 `HomeTests`、`PlayerFeatureTests`。
  - 模拟器名以本机 `xcodebuild -showdestinations` 为准（常见 iPhone 17 / OS 26.x）。
- **Legacy**：`cd htz && pod install`，再 `open htz/htz.xcworkspace`，scheme `htz`。`htz/Pods` 不入库。

## Stack
- HTZNext：Swift 5.9+ / iOS 16+ / SwiftUI / TCA / SPM（`Packages/`：NetworkKit、HTZAudio、PlayerFeature、Home、Auth、DesignSystem）
- Playback：`HTZAudio.AudioEngine`（`@MainActor` + `AVPlayer`）；TCA 经 `\.playerClient`、`\.playback`（`PlayerRelay`）
- Downloads：`\.downloads` / `DownloadCenter`；网络：`\.library` → `LibraryAPI`
- Share：`\.shareClient`（`ShareClient`）；微信 SDK 只在 app target、真机分支注入（`#if !targetEnvironment(simulator)`），并链接 `htz/Pods/WechatOpenSDK`。真机编译前先在 `htz/` 执行 `pod install`。
- Dialogs：清空/退出等用 `htzConfirmSheet`；居中付费弹窗用 `htzCenterDialog`（勿再加系统 `confirmationDialog`/`alert` 做同类确认）
- Legacy：UIKit + CocoaPods + SnapKit；类型前缀 `HTZ`

## Layout & conventions
- App shell：`HTZNext/HTZNext/`（`RootView` 用 `@ComposableArchitecture.Bindable` + `.sending` 绑 `showFullPlayer`）
- Features：`Packages/Features/{Home,Player,Auth}/`；「我的」在 `Home/Profile/`
- Shared：`Packages/{NetworkKit,HTZAudio,DesignSystem}/`；Android 对照图标在 `DesignSystem/.../Images.xcassets`（`HTZImage`）
- OpenSpec：`openspec/`；提交：`<Type>: <imperative>`。密钥走 xcconfig，模拟器样例凭据包在 `#if targetEnvironment(simulator)`。
- 播放：点上一集/下一集**始终按列表顺序**；随机模式只在**播完自动切歌**时生效；切歌失败须恢复上一集。

## Current status (2026-11-11)
- `master` 已快进到 `384f8e9`，与 `feature/rf-zhihao` 相同。工作区干净。这条线是 HTZNext 发布线。
- 主机：`http://app.htzchina.org:9100`。本机若开 fake-IP 代理导致 9100 超时，需直连该域名。
- 2026-11-11 真机验收通过：手机号发码并登录；反馈 `image_urls` 按 JSON 数组字符串入库；微信分享；登录 `token` 写入 Keychain，杀进程后重新打开仍为已登录。
- 没有进行中的 OpenSpec 变更。`audio-engine-v2` 已归档；播放器以 `openspec/specs/player/spec.md` 为准（`@MainActor` + `AVPlayer`）。任务 4.5–4.7（播放条 UI 测试、后台播放手测、回滚彩排）延期，不是下一步。ADR-004（用 Actor 包 FreeStreamer）已废弃。
