## Why

HTZNext 已经能登录、浏览首页、打开专辑并用签名地址播放单曲，但专辑 Tab 和「我的」仍是占位，播放器不能拖进度、切集、锁屏控制或显示歌词。需要在现有 SwiftUI + TCA 工程上补齐主路径，而不是回到旧 UIKit 工程 `htz/`。

本变更承接 `audio-engine-v2` 里明确延后的播放能力，并补上专辑、搜索、我的、下载和账号。实现过程中以本目录的 `tasks.md` 和 `specs/` 为准；每完成一项就勾选任务，能力定稿后把 delta spec 同步进 `openspec/specs/`。

## What Changes

- 播放器从单曲播放扩展为专辑队列：拖动进度、倍速、上一集/下一集、播完自动下一集、全屏播放页、锁屏与控制中心。
- 播放时解析签名歌词并按 LRC 高亮；切集和暂停时上报收听进度。
- 专辑 Tab 展示全部专辑，并保留付费/已购字段与角标。未授权章节继续拦截，不做应用内购买。
- 首页增加搜索，结果可进入专辑或直接播放。
- 「我的」补齐收藏、历史、通知、设置和个人资料。
- 支持后台下载和离线播放。付费文件的本地 AES 加密不做。
- 账号补齐绑定手机、十年持志网页、意见反馈。明文 HTTP 增加传输安全例外。

## Capabilities

### New Capabilities

- `search`: 按关键词搜索专辑和章节，并保留本地搜索历史。
- `profile`: 我的页，含收藏、播放历史、通知、设置和个人资料。
- `downloads`: 单集/专辑下载、下载列表、已下载内容离线播放。
- `account`: 绑定手机号、十年持志 WebView、意见反馈。

### Modified Capabilities

- `player`: 队列、seek、倍速、全屏播放页、锁屏控制、歌词、收听记录。
- `app-shell`: 中文底栏，专辑和我的不再是占位页，迷你条可打开全屏播放页。
- `album-detail`: 把当前专辑章节队列交给播放器，展示付费状态。
- `network-kit`: 补齐搜索、收藏、历史、通知、资料、下载和反馈所需接口与模型。
- `home-ui`: 首页搜索入口；专辑列表复用到专辑 Tab。

## Impact

- `Packages/HTZAudio`、`Packages/Features/Player`、`Packages/Features/Home`、`Packages/NetworkKit`、`HTZNext`。
- 新增 SPM feature：`Search`、`Profile`、`Downloads`（账号页可放在 `Profile` 或 `AuthFeature`）。
- 不修改旧工程 `htz/`。
- 不实现桌面悬浮歌词、自定义锁屏页、小组件、短视频、AI 对话、应用内购买、极光推送。

## Non-goals

- 不迁移或删除旧 UIKit 工程。
- 不把通义 API Key 放进客户端。
- 不在本变更里接「通过 Apple 登录」的证书；只保留后续可加的账号模型。
