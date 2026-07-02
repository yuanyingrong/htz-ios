import SwiftUI
import ComposableArchitecture
import Home
import NetworkKit
import AuthFeature

class AppDelegate: NSObject, UIApplicationDelegate, WXApiDelegate {
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

@main
struct HTZApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // By default, we do NOT set up the test account, forcing the login gate.
        // If the developer wants to test list/playback directly without WeChat,
        // they can uncomment the line below:
        // AuthManager.shared.setupTestAccount()
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
