import SwiftUI
import ComposableArchitecture
import Home
import NetworkKit
import AuthFeature
import PlayerFeature

#if !targetEnvironment(simulator)
/// Sends an episode link card through the WeChat SDK (chat / moments / favourites), like Android's `WXShareUtil`.
enum WeChatSharing {
    static func share(_ content: ShareContent, scene: WeChatScene) async -> Bool {
        let thumbnail = await thumbnailData(from: content.imageURL)
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let page = WXWebpageObject()
                page.webpageUrl = content.url.absoluteString
                let message = WXMediaMessage()
                message.title = content.title
                message.description = content.description
                message.thumbData = thumbnail
                message.mediaObject = page
                let request = SendMessageToWXReq()
                request.bText = false
                request.message = message
                switch scene {
                case .session: request.scene = Int32(WXSceneSession.rawValue)
                case .timeline: request.scene = Int32(WXSceneTimeline.rawValue)
                case .favorite: request.scene = Int32(WXSceneFavorite.rawValue)
                }
                WXApi.send(request) { continuation.resume(returning: $0) }
            }
        }
    }

    /// WeChat rejects thumbnails over 32 KB.
    private static func thumbnailData(from url: URL?) async -> Data? {
        guard let url, let (data, _) = try? await URLSession.shared.data(from: url), let image = UIImage(data: data) else { return nil }
        let side: CGFloat = 150
        let scale = min(1, side / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        for quality in stride(from: 0.8, through: 0.2, by: -0.2) {
            if let jpeg = resized.jpegData(compressionQuality: quality), jpeg.count <= 32 * 1024 { return jpeg }
        }
        return nil
    }
}
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Register WeChat SDK
        #if !targetEnvironment(simulator)
        WXApi.registerApp("wx411fef9024bd3b5b", universalLink: "https://app.neixinchan.com:9500/")
        #endif
        
        // Inject real WeChatClient implementation into TCA dependencies
        #if !targetEnvironment(simulator)
        let sendAuthRequestClosure: @Sendable () async throws -> Bool = { () async throws -> Bool in
            return await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    let req = SendAuthReq()
                    req.scope = "snsapi_userinfo"
                    req.state = "htz_oauth"
                    req.openID = "wx411fef9024bd3b5b"
                    WXApi.send(req) { success in
                        continuation.resume(returning: success)
                    }
                }
            }
        }
        #endif
        
        prepareDependencies {
            #if !targetEnvironment(simulator)
            $0.weChatClient = WeChatClient(
                isInstalled: { WXApi.isWXAppInstalled() },
                sendAuthRequest: sendAuthRequestClosure
            )
            $0.shareClient = ShareClient(
                isWeChatInstalled: { WXApi.isWXAppInstalled() },
                shareToWeChat: { content, scene in await WeChatSharing.share(content, scene: scene) }
            )
            #else
            // In simulator, we fall back to a mock that simulates successful auth code returning after 1s
            $0.weChatClient = WeChatClient(
                isInstalled: { true },
                sendAuthRequest: {
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        NotificationCenter.default.post(
                            name: NSNotification.Name("WeChatAuthCodeNotification"),
                            object: nil,
                            userInfo: ["code": "mock_auth_code_from_simulator"]
                        )
                    }
                    return true
                }
            )
            #endif
        }
        
        return true
    }

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        if identifier == "cn.org.htz.next.downloads" {
            DownloadCenter.shared.backgroundCompletion = completionHandler
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        #if !targetEnvironment(simulator)
        return WXApi.handleOpen(url, delegate: self)
        #else
        return false
        #endif
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        #if !targetEnvironment(simulator)
        return WXApi.handleOpenUniversalLink(userActivity, delegate: self)
        #else
        return false
        #endif
    }
}

#if !targetEnvironment(simulator)
extension AppDelegate: WXApiDelegate {
    func onReq(_ req: BaseReq) {}
    
    func onResp(_ resp: BaseResp) {
        if let authResp = resp as? SendAuthResp {
            if authResp.errCode == 0, let code = authResp.code {
                NotificationCenter.default.post(
                    name: NSNotification.Name("WeChatAuthCodeNotification"),
                    object: nil,
                    userInfo: ["code": code]
                )
            } else {
                let errorMsg = authResp.errStr ?? "微信登录失败"
                NotificationCenter.default.post(
                    name: NSNotification.Name("WeChatAuthCodeNotification"),
                    object: nil,
                    userInfo: ["error": errorMsg]
                )
            }
        }
    }
}
#endif

@main
struct HTZApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("-HTZTestAccount") {
            AuthManager.shared.setupTestAccount()
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    #if !targetEnvironment(simulator)
                    _ = WXApi.handleOpen(url, delegate: appDelegate)
                    #endif
                }
        }
    }
}
