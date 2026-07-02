# Android 登录体系调研报告

## 1. 结论摘要
1. **微信登录是唯一核心入口**：Android 仅实现了微信一键登录为主链路，虽有遗留的密码注册代码，但并未在现有主流程中开放。
2. **强鉴权设计**：APP 核心功能（首页推荐、专辑列表、搜索、播放、历史等）均强依赖登录态。未登录时列表为空且展示登录按钮，强行播放会弹窗“请登录后重试”并拦截播放。
3. **不存在真正的“游客态”**：未登录状态下，网络层请求会被前置条件（`AccountManager.checkLogin`）直接拦截，不会发出。
4. **不存在本地写死 Token**：Android 没有写死 Token 机制。iOS 现在的写死 Token 大概率是重构前期为了绕过业务鉴权拦截而放置的开发者个人 Token，用于跑通拉取列表和播放的最小链路。
5. **Token 存储非常简单**：通过原生 `SharedPreferences` 明文存储 `token` 及用户信息。
6. **无自动续期机制（无 Refresh Token）**：未发现对网络 401 状态码的全局拦截与处理，也没有 Refresh Token 逻辑。若 Token 失效，可能依赖后端长期有效或用户手动重新登录。
7. **多后台域名结构**：微信授权登录（获取 Token）、业务内容（音频/专辑）与用户个人信息（同步与更新）分为不同域名（`39.105.x.x:9100` 和 `121.36.x.x:8082`）处理。

## 2. Android 当前登录能力总览
APP 高度依赖登录。所有核心功能使用前均通过 `AccountManager.checkLogin()` 检查状态，未登录会重定向到 `WXLoginActivity` 唤起微信登录。
**主要流程**：唤起微信 -> 获取 Code -> APP调用后端 `/post/login` 获取 Token 和用户信息 -> 并发同步信息到个人服务器 -> 保存本地 SharedPreferences。

## 3. 登录入口与用户流程
* **首页是否强制登录**：启动不强制，但首页（推荐）、专辑页等 Fragment 会在 `onResume` 中检查，如果未登录，直接显示 `emptyView` 和 `loginView`。
* **播放前是否要求登录**：是。`HTZMediaPlaybackService.playSutraItemObject()` 中存在拦截，未登录不播放并 Toast “请登录后重试”。
* **触发登录场景**：点击“历史”、“收藏”、“下载”、“通知”、“设置”、“搜索”或列表的空视图登录按钮。
* **游客态**：仅能看到基础壳子，几乎无可用业务数据，无法播放网络或本地业务音频。

## 4. 登录方式与第三方 SDK
* **微信登录**：核心主链路。依赖 `com.tencent.mm.opensdk:wechat-sdk-android`。
  - 入口：各类需要鉴权的点击跳转。
  - 流程：请求自有服务器获取微信 AppID -> 初始化 SDK -> 发起 `SendAuth.Req`。
* **手机号绑定**：存在 `BindTelephoneActivity`，但属于登录后在“个人中心”补充绑定手机号，通过 `/api/telephone/getSmsCode` 和 `/api/telephone/bindTelephone` 实现，非主登录入口。
* **密码登录**：代码中有 `RegisterActivity` 和 `LoginAsyncTask`，但没有任何入口可以进入，属于废弃/遗留代码。

## 5. 登录接口与数据结构

| 场景 | 接口 | 方法 | 请求参数 | 返回（提取）字段 | 备注 |
| -- | -- | -- | -- | ---- | -- |
| 获取微信AppID | `http://121.36.173.141:8082/htz-api-pyservice/api/v1/getaksk` | GET | `appName=htz` | `accessKey` (AppID) | 动态获取 SDK 秘钥 |
| 换取 Token | `http://39.105.174.143:9100/post/login` | POST | `code` (微信code) | `token`, `wx_login_resp` (含 unionid, nickname 等) | 核心登录接口 |
| 检查/拉取用户信息 | `http://121.36.173.141:8082/htz-api-pyservice/api/v1/userinfo/get` | GET | `unionid` | `data` 对象 | 判断服务器是否已有信息 |
| 保存微信用户信息 | `.../api/v1/userinfo/add` | POST | 组装的用户信息 JSON | 无 | Token换取后，若上一步查不到，则调用同步 |
| 更新用户信息 | `.../api/v1/userinfo/update` | POST | 组装的用户信息 JSON | 无 | 包含修改头像、性别、签名等 |
| 发送验证码 | `.../api/telephone/getSmsCode` | POST | `unionid`, `telephone` | `code` (验证码文本) | 绑定手机号时调用 |
| 绑定手机号 | `.../api/telephone/bindTelephone` | POST | `unionid`, `telephone`, `code` | `true/false` | 绑定手机号时调用 |

*未发现专门注销账号、刷新 Token 的接口。*

## 6. 登录态保存与恢复机制
* **存储方式**：`SharedPreferences`，文件名为 `userInfo.xml`。
* **保存字段**：
  * `token`：接口返回的 AccessToken。
  * `responseInfo`：接口返回的 JSON 字符串（包含 `unionid`, `nickname`, `headimgurl`, `sex`, `city`, `telephone`, `sign` 等）。
* **加密机制**：无加密，明文存储。
* **状态恢复**：每次启动 APP，`AccountManager` 会从 SharedPreferences 直接读取内存并供拦截器使用。
* **清理机制**：`AccountManager.logout()` 会将 `token` 和 `responseInfo` 置为空字符串/null。

## 7. Token 机制与网络层注入
* **Token 注入**：`HttpClientUtils` 在构造 `Request` 时，通过 `AccountManager.getToken()` 取值并手动添加到 Header 的 `token` 字段（注意：Key 就是小写的 `token`，并非 `Authorization`）。
* **Token 过期处理**：代码中**无**全局 401 拦截处理，也无 RefreshToken。猜测 Token 在服务端的生命周期较长，失效后需用户手动处理。

## 8. 未登录 / 已登录权限差异

| 功能 | 未登录是否可用 | 登录后变化 | 触发登录时机 |
| -- | ------- | ----- | ------ |
| **播放音频** | 否 | 可播放完整内容 | 触发播放请求时 (`HTZMediaPlaybackService`) |
| **拉取专辑** | 否 | 展示列表 | 打开 Fragment 时自动检查并显示登录按钮 (`AlbumFragment`) |
| **推荐内容** | 否 | 展示列表 | 打开 Fragment 时自动检查并显示登录按钮 (`HomeFragment`) |
| **收藏/历史**| 否 | 可访问 | 点击菜单入口时 (`MyFragment`) |
| **搜索** | 否 | 可访问 | 点击搜索栏时 (`HomeFragment`) |

## 9. 当前写死 token 问题分析
* **Android 现状**：Android 中**没有**写死 Token。它的 Token 默认是 `""`，为空时 `AccountManager.checkLogin` 返回 `false`，从而在业务发起网络请求前，直接在代码层把请求拦下。
* **iOS 写死 Token 原因推测**：因为该产品的接口强校验 Token，且 Android 在调用获取列表、拉取音频接口前不仅依赖请求头的 Token，甚至直接不执行代码。iOS 开发者在重构初期尚未接入复杂的微信登录逻辑，为了能测试“列表拉取”和“音频播放”的 MVP 闭环，使用了个人的合法 Token 写死在代码中绕过鉴权。
* **iOS 替代方案建议**：MVP 阶段如果不想立刻接入微信登录 SDK，可以做一个隐藏的“开发者调试面板”，允许手动输入 Token。但在产品发布层面，不存在所谓的“游客 Token”，必须完成登录。

## 10. 退出登录 / token 失效 / 异常处理
* **退出登录**：设置页点击退出 -> `AccountManager.logout()` 清除本地 SP 缓存 -> `HTZMediaPlayManager.getInstance().dismissView()` 隐藏全局播放组件。
* **异常处理**：如前述，未实现网络层 401 自动触发登出，属于设计缺陷或弱管理。

## 11. Android 代码结构索引
* **状态与数据管理**：`src/main/java/cn/org/htz/manager/AccountManager.java` (核心鉴权与数据读写逻辑)
* **微信登录界面**：`src/main/java/cn/org/htz/activity/WXLoginActivity.java`
* **微信回调处理**：`src/main/java/cn/org/htz/wxapi/WXEntryActivity.java` (在此请求后端换取 Token 并派发同步)
* **网络请求封装**：`src/main/java/cn/org/htz/net/HttpClientUtils.java` (注入 `token` Header)
* **API 域名配置**：`src/main/java/cn/org/htz/constants/HTZServerConstants.kt`
* **绑定手机**：`src/main/java/cn/org/htz/activity/BindTelephoneActivity.kt`
* **鉴权拦截拦截点**：`src/main/java/cn/org/htz/service/HTZMediaPlaybackService.java` (播放拦截)

## 12. 对 iOS 重构项目的 MVP 建议
1. **MVP 最小登录范围**：必须实现**微信授权 -> 后端换取 Token -> 存本地**的链路。否则核心的专辑与播放功能无法交付验收。不用急着做手机号绑定和用户信息更新。
2. **需要暂缓的能力**：修改头像、编辑签名、手机号绑定等外围功能可以放在二期。
3. **Token 管理**：仿照 Android 使用 `UserDefaults` (或 `Keychain` 更安全) 存储。业务网络层需在 Header 中统一注入 `token: xxxxx`。
4. **游客态处理**：无需花费精力设计复杂的游客态。如果未登录，按照 Android 逻辑，直接展示引导登录的 EmptyView 并拦截播放动作即可。

## 13. 可转 OpenSpec 的规格准备材料

**1. Problem / 背景问题**
iOS 重构项目中当前使用写死 Token 来绕过鉴权，缺乏完整的登录闭环。为了让项目能脱离开发环境成为可用 MVP，必须重构登录模块以获取真实的 AccessToken。

**2. Goal / 目标**
实现最小可用登录闭环（微信登录），移除写死 Token，在业务网络请求中自动注入真实 Token，在未登录状态下正确拦截和引导。

**3. Non-Goals / 暂不做**
* 多端账号合并。
* 刷新 Token (Refresh) 机制设计（对齐原版）。
* 短信验证码注册 / 手机号绑定。

**4. User Stories**
* 作为未登录用户，当我打开首页或试图播放时，我希望能看到明确的登录提示。
* 作为用户，我可以通过微信一键授权登录 App。
* 作为已登录用户，关闭并重新打开 App 时我依然保持登录状态。

**5. Requirements**
* 需要支持微信 SDK 授权并换取 Token。
* 业务网络层自动在 Header 中带上 `token` 字段。
* 全局鉴权：如果未登录，核心功能无法使用并唤起登录流程。

**6. API Contracts**
* **Headers**: `token: <AccessToken>`
* **Endpoints**:
  * 微信 Token 换取: `POST http://39.105.174.143:9100/post/login`
  * Body: `{"code": "xxx"}`

**7. State Model**
* `LoggedOut`: 本地无 Token。所有需要鉴权的视图展示 LoginView。
* `LoggedIn`: 内存/本地持有 Token 和 UserInfo。

**8. UI Flow**
未登录 -> 列表页展示空状态(含登录按钮) -> 点击进入 WXLoginActivity -> 点击唤起微信 -> 微信授权返回 -> 成功后存储 Token -> 返回列表页触发自动刷新。

**9. Edge Cases**
用户取消微信授权；无网络导致换取 Token 失败；微信未安装。

**10. Migration Plan**
移除全局硬编码的 Token，在 Network 请求模块重构 Header 注入逻辑。

**11. Test Plan**
* 卸载微信的情况下提示正确。
* 正常授权返回后列表能刷新。
* 重启 APP 后状态得以保留。

**12. Risks & Questions**
* 401 拦截处理：Android 无全局 401 失效处理，iOS 是否需要补全？

## 14. 风险、疑问与需要产品 / 后端确认的问题
1. **401 处理缺失**：Android 缺乏 Token 失效的处理机制，是否需要在 iOS 中新增补全（即收到 401 自动登出并跳登录页）？
2. **强鉴权必要性**：产品设计上，首页列表和专辑是否真的不给未登录用户看任何预览数据？目前 Android 做法是全部封杀。建议确认这是否符合当下的产品预期。
3. **游客数据隔离**：目前后端似乎不接收无 Token 的拉取请求，后续是否有计划开放游客级 Token 供“试听”或“预览”？
4. **废弃代码确认**：Android 代码中的 `RegisterActivity` 和密码验证相关接口是否已彻底在服务端下线？如果下线，iOS 不必预留相关设计。

## 15. 附录：关键代码片段

**AccountManager.java (核心鉴权):**
```java
public static boolean checkLogin(boolean launchLoginActivityIfNotLogin) {
    if (TextUtils.isEmpty(getToken())) {
        if (launchLoginActivityIfNotLogin) {
            Intent loginIntent = new Intent(ContextUtil.getContext(), WXLoginActivity.class);
            loginIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP
                    | Intent.FLAG_ACTIVITY_NEW_TASK);
            ContextUtil.getContext().startActivity(loginIntent);
        }
        return false;
    }
    return true;
}
```

**HTZMediaPlaybackService.java (播放鉴权拦截):**
```java
private void playSutraItemObject(SutraItemObject sutraItemObject) {
    if (!AccountManager.checkLogin(false)) {
        ToastUtil.showToastInCenter("请登录后重试！");
        return;
    }
    // ... 发起播放 ...
}
```

**HttpClientUtils.java (Token注入):**
```java
public static String postWithToken(String url, String json) throws IOException {
    RequestBody body = RequestBody.create(JSON, json);
    Request request = new Request.Builder()
            .addHeader("content-type", "application/json")
            .addHeader("token", AccountManager.getToken())
            .url(url)
            .post(body)
            .build();
    Response response = client.newCall(request).execute();
    return response.body().string();
}
```