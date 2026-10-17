# Repository Guidelines

## What this is
黄庭禅 iOS：双轨仓库。现役开发面是 **HTZNext**（SwiftUI + TCA + SPM）。`htz/` 是 CocoaPods UIKit 遗留工程，仅在修线上兼容或对照行为时改动。

## How to run
- **HTZNext（默认）**：`open HTZNext/HTZNext.xcodeproj`，scheme `HTZNext`。
  - Build：`xcodebuild -project HTZNext/HTZNext.xcodeproj -scheme HTZNext -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build`
  - 模拟器名以本机 `xcodebuild -showdestinations` 为准（常见 iPhone 17 / OS 26.x）。
- **Legacy**：`cd htz && pod install`，再 `open htz/htz.xcworkspace`，scheme `htz`。

## Stack
- HTZNext：Swift 5.9+ / iOS 16+ / SwiftUI / TCA / SPM（`Packages/`：NetworkKit、HTZAudio、PlayerFeature、Home、DesignSystem）
- Playback：`HTZAudio.AudioEngine`（`@MainActor` + `AVPlayer`），经 `PlayerClient` / `PlayerRelay` 接入 TCA
- Legacy：UIKit + CocoaPods + SnapKit；类型前缀 `HTZ`

## Layout & conventions
- App shell：`HTZNext/HTZNext/`（`RootView`、Tab、登录桥）
- Features：`Packages/Features/{Home,Player,Auth}/`
- Shared：`Packages/{NetworkKit,HTZAudio,DesignSystem}/`
- OpenSpec：`openspec/`（提案/规格）；归档用 openspec archive 流程
- 提交：`<Type>: <imperative>`（如 `Feat: add play modes`）。密钥走 xcconfig / build settings，勿入库；模拟器样例凭据包在 `#if targetEnvironment(simulator)`。

## Current status (2026-10-17)
- 分支 `feature/rf-zhihao`：首页/专辑/播放器/歌词/播放模式/收藏开关/下载管理/续播 seek 已在工作区落地；部分改动未提交。
- 活动变更：`openspec/changes/audio-engine-v2`（MVP 已完成；剩余 UI 测试 / 手动验证 / 过时 rollback 检查点）。
- 下一步：提交播放能力补齐 → 归档或收口 `audio-engine-v2` → 需要时对照 Android 补缺口。
