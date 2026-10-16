## Context

HTZNext 使用 TCA 和 SPM。播放内核是 `AudioEngine` actor 包住单个 `AVPlayer`，状态经 `AsyncStream` 进 `PlayerFeature`。点章节时 `AlbumDetailFeature` 先请求 `POST /get/sutra/item/file_url`，成功后把 `pendingPlayItem` 交给根上的 `PlayerFeature`。专辑 Tab 和 Profile Tab 仍是占位文案。

主接口是 `http://39.105.174.143:9100`。用户资料、短信、通知、反馈在 `http://app.htzchina.org:8082`。十年持志页面是 `http://app.htzchina.org/tenyears/#/tenyearsHome`。iOS 默认拦截明文 HTTP。

`audio-engine-v2` 的 MVP 已落地。本设计实现它延后的播放能力，队列放在 `PlayerFeature` 而不是 `AVQueuePlayer`，因为每一集的签名地址都会过期，不能提前整队塞进播放器。

## Goals / Non-Goals

**Goals:**

- 在现有签名地址链路上听完一张专辑：队列、seek、倍速、上下集、全屏页、锁屏。
- 专辑、搜索、我的、下载、账号都走现有 HTTP 接口。
- 每一期都能编译，且不破坏登录和单曲播放。

**Non-Goals:**

- 不用 `AVQueuePlayer` 预加载整张专辑。
- 不做付费音频的 `.htze` 本地加密。
- 不做应用内购买、网页支付、AI、视频、悬浮歌词、小组件、极光推送。
- 不改旧 `htz/` 工程。

## Decisions

### 1. 队列放在 PlayerFeature

`AudioEngine` 继续持有一个 `AVPlayer`，新增 `seek(to:)` 和 `setRate(_:)`。`PlayerFeature` 保存当前专辑的章节列表和下标。切到下一集时再调用 `getSutraItemFileURL`。拿不到地址就停在当前集并提示，不自动跳过到未知权限的下一集。

`PlayerItem` 增加 `sutraId`，以便锁屏和自动下一集知道向哪张专辑要签名地址。

### 2. 全屏播放页由迷你条打开

`NowPlayingBarView` 点击后以 sheet 展示全屏播放页。播放/暂停、进度、倍速共用同一个 `PlayerFeature` store，不另建一套状态。

### 3. 锁屏只走系统正在播放

用 `MPNowPlayingInfoCenter` 和 `MPRemoteCommandCenter`。不建自定义锁屏界面。封面用当前 item 的 `imageUrl`。

### 4. 歌词用签名地址里的 LRC

`SignedURLs.originalLyric` 和 `explanationLyric` 已经在响应模型里。播放页下载文本，解析 `[mm:ss.xx]`，按 `currentTime` 高亮。两种歌词用同一解析器，界面上切换。

### 5. 专辑模型保留付费字段

`Album` 补 `description`、`isPaid`、`price`、`isPurchased`、`paidUrl`。`HomeClient` 重组专辑时必须带上这些字段，不能只回写 id、name、封面。列表角标：未购付费显示「付费」，已购显示「已购」。

### 6. 新页面按现有 feature 模块加

搜索、我的、下载各自成为 SPM target，由 `RootView` 接入。网络模型和方法放在 `NetworkKit` / 对应 Client，不在 View 里直接调 Moya。

下载使用后台 `URLSession`。本地文件存在应用沙盒。已下载章节播放时把本地文件 URL 交给 `AudioEngine`，不再请求签名地址。

### 7. 明文 HTTP

在 `HTZNext/Info.plist` 为现有主服务和个人服务主机增加 ATS 例外。服务改为 HTTPS 后再删除例外。

### 8. 规格怎么更新

实现时改代码，并同时把本变更 `tasks.md` 里对应项从 `- [ ]` 改为 `- [x]`。如果实现和本文不一致，先改 `design.md` 和对应 `specs/`，再改代码。全部完成后，把 delta spec 合并进 `openspec/specs/<capability>/spec.md`，再归档本变更。

## Risks / Trade-offs

- 签名地址约一小时过期。长列表里拖很久再切集时要重新要地址，失败时留在当前集并提示。
- 收听记录若上报失败，不打断播放，只记日志。
- 下载不做加密时，已购音频会以普通文件留在沙盒里。这是本期接受的风险。

## Migration Plan

按 `tasks.md` 的顺序做：播放闭环、专辑 Tab、搜索、我的、下载、账号。每段结束都要能从首页点进章节并播放。回滚时按任务段撤回，不需要数据迁移。

## Open Questions

- 搜索接口以旧工程 `API.search` 为准。若主服务路径和 Android `/search/search` 不一致，以实现时抓到的真实响应为准，并回写本设计。
- 「通过 Apple 登录」只留登录页入口和 `appleUserId` 字段，本变更不接证书。
