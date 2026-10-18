# Repository Guidelines

## What this is
黄庭禅 iOS：双轨仓库。现役开发面是 **HTZNext**（SwiftUI + TCA + SPM）。`htz/` 是 CocoaPods UIKit 遗留工程，仅在修线上兼容或对照行为时改动。

## How to run
- **HTZNext（默认）**：`open HTZNext/HTZNext.xcodeproj`，scheme `HTZNext`。
  - Build：`xcodebuild -project HTZNext/HTZNext.xcodeproj -scheme HTZNext -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build`
  - 模拟器名以本机 `xcodebuild -showdestinations` 为准（常见 iPhone 17 / OS 26.x）。
- **Legacy**：`cd htz && pod install`，再 `open htz/htz.xcworkspace`，scheme `htz`。

## Stack
- HTZNext：Swift 5.9+ / iOS 16+ / SwiftUI / TCA / SPM（`Packages/`：NetworkKit、HTZAudio、PlayerFeature、Home、Auth、DesignSystem）
- Playback：`HTZAudio.AudioEngine`（`@MainActor` + `AVPlayer`）；TCA 经 `\.playerClient`、`\.playback`（`PlayerRelay`）
- Downloads：`\.downloads` / `DownloadCenter`；网络：`\.library` → `LibraryAPI`
- Legacy：UIKit + CocoaPods + SnapKit；类型前缀 `HTZ`

## Layout & conventions
- App shell：`HTZNext/HTZNext/`（`RootView` 用 `@ComposableArchitecture.Bindable` + `.sending` 绑 `showFullPlayer`）
- Features：`Packages/Features/{Home,Player,Auth}/`；「我的」在 `Home/Profile/`
- Shared：`Packages/{NetworkKit,HTZAudio,DesignSystem}/`
- OpenSpec：`openspec/`；提交：`<Type>: <imperative>`。密钥走 xcconfig，模拟器样例凭据包在 `#if targetEnvironment(simulator)`。
- 播放：点上一集/下一集**始终按列表顺序**；随机模式只在**播完自动切歌**时生效；切歌失败须恢复上一集。

## Current status (2026-10-18)
- 分支 `feature/rf-zhihao`：相对 `origin` 有大量**未提交**改动（Android 对照重构 + 播放器切歌/Perception 修复），待 review / 提交。
- 主机：`http://app.htzchina.org:9100`。本机若开 fake-IP 代理导致 9100 超时，需直连该域名。
- 已知：模拟器 Keychain 相关测试在 HEAD 上即失败；手机号登录未对真实服务端验收。
- 活动变更：`openspec/changes/audio-engine-v2`（MVP 完成；残留 UI/手动验证任务）。
