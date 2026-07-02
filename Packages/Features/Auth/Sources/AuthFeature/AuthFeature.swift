import Foundation
import ComposableArchitecture
import NetworkKit
import Combine

// MARK: - WeChat Client Interface
public struct WeChatClient: Sendable {
    public var isInstalled: @Sendable () -> Bool
    public var sendAuthRequest: @Sendable () async throws -> Bool
    
    public init(
        isInstalled: @escaping @Sendable () -> Bool,
        sendAuthRequest: @escaping @Sendable () async throws -> Bool
    ) {
        self.isInstalled = isInstalled
        self.sendAuthRequest = sendAuthRequest
    }
}

// Default to test/mock value so the SPM module compiles without referencing WXApi
extension WeChatClient: DependencyKey {
    public static let liveValue = Self(
        isInstalled: { false },
        sendAuthRequest: { false }
    )
    
    public static let testValue = Self(
        isInstalled: { true },
        sendAuthRequest: { true }
    )
}

extension DependencyValues {
    public var weChatClient: WeChatClient {
        get { self[WeChatClient.self] }
        set { self[WeChatClient.self] = newValue }
    }
}

// MARK: - Auth Client Dependency Registration
public struct AuthClientDependencyKey: DependencyKey {
    public static let liveValue: AuthClientProtocol = AuthClient()
    public static let testValue: AuthClientProtocol = AuthClient()
}

extension DependencyValues {
    public var authClient: AuthClientProtocol {
        get { self[AuthClientDependencyKey.self] }
        set { self[AuthClientDependencyKey.self] = newValue }
    }
}

// MARK: - Auth Feature Reducer
@Reducer
public struct AuthFeature {
    @ObservableState
    public struct State: Equatable {
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var isLoggedIn: Bool = false
        
        public init() {
            self.isLoggedIn = AuthManager.shared.isLoggedIn
        }
    }
    
    public enum Action: Equatable {
        case wechatLoginTapped
        case receiveAuthCode(String)
        case tokenResponse(Swift.Result<LoginModel, NetworkError>)
        case syncResponse(Swift.Result<Bool, NetworkError>)
        case logout
        case clearError
    }
    
    @Dependency(\.weChatClient) var weChatClient
    @Dependency(\.authClient) var authClient
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .wechatLoginTapped:
                return handleWechatLoginTapped(state: &state)
                
            case let .receiveAuthCode(code):
                return handleReceiveAuthCode(state: &state, code: code)
                
            case let .tokenResponse(result):
                return handleTokenResponse(state: &state, result: result)
                
            case .syncResponse:
                return handleSyncResponse(state: &state)
                
            case .logout:
                return handleLogout(state: &state)
                
            case .clearError:
                return handleClearError(state: &state)
            }
        }
    }
    
    // MARK: - Reducer Helpers
    
    private func handleWechatLoginTapped(state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        
        if weChatClient.isInstalled() {
            return .run { send in
                let listenerTask = Task {
                    for await notification in NotificationCenter.default.notifications(named: NSNotification.Name("WeChatAuthCodeNotification")) {
                        if let code = notification.userInfo?["code"] as? String {
                            await send(.receiveAuthCode(code))
                            break
                        } else if let error = notification.userInfo?["error"] as? String {
                            await send(.tokenResponse(Swift.Result<LoginModel, NetworkError>.failure(.apiError(error))))
                            break
                        }
                    }
                }
                
                do {
                    let success = try await weChatClient.sendAuthRequest()
                    if !success {
                        listenerTask.cancel()
                        await send(.tokenResponse(Swift.Result<LoginModel, NetworkError>.failure(.apiError("无法唤起微信"))))
                    }
                } catch {
                    listenerTask.cancel()
                    await send(.tokenResponse(Swift.Result<LoginModel, NetworkError>.failure(.apiError(error.localizedDescription))))
                }
            }
        } else {
            state.isLoading = false
            state.errorMessage = "您的设备未安装微信"
            return .none
        }
    }
    
    private func handleReceiveAuthCode(state: inout State, code: String) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        
        return .run { send in
            do {
                let response = try await authClient.login(code: code)
                    .eraseToAnyPublisher()
                    .async()
                
                if response.code == 200, let loginModel = response.data {
                    await send(.tokenResponse(Swift.Result<LoginModel, NetworkError>.success(loginModel)))
                } else {
                    await send(.tokenResponse(Swift.Result<LoginModel, NetworkError>.failure(.apiError(response.msg ?? "登录失败"))))
                }
            } catch {
                await send(.tokenResponse(Swift.Result<LoginModel, NetworkError>.failure(error as? NetworkError ?? .unknown)))
            }
        }
    }
    
    private func handleTokenResponse(state: inout State, result: Swift.Result<LoginModel, NetworkError>) -> Effect<Action> {
        switch result {
        case let .success(loginModel):
            AuthManager.shared.token = loginModel.token
            AuthManager.shared.unionid = loginModel.unionId ?? loginModel.wxLoginResp?.unionid
            
            return .run { send in
                do {
                    let response = try await authClient.syncUserInfo(loginModel: loginModel)
                        .eraseToAnyPublisher()
                        .async()
                    
                    if response.code == 200 || response.code == 0 {
                        await send(.syncResponse(Swift.Result<Bool, NetworkError>.success(true)))
                    } else {
                        await send(.syncResponse(Swift.Result<Bool, NetworkError>.failure(.apiError(response.msg ?? "同步用户信息失败"))))
                    }
                } catch {
                    await send(.syncResponse(Swift.Result<Bool, NetworkError>.success(true)))
                }
            }
            
        case let .failure(error):
            state.isLoading = false
            state.errorMessage = "微信登录失败: \(error.localizedDescription)"
            AuthManager.shared.logout()
            return .none
        }
    }
    
    private func handleSyncResponse(state: inout State) -> Effect<Action> {
        state.isLoading = false
        state.isLoggedIn = true
        return .none
    }
    
    private func handleLogout(state: inout State) -> Effect<Action> {
        AuthManager.shared.logout()
        state.isLoggedIn = false
        state.isLoading = false
        state.errorMessage = nil
        return .none
    }
    
    private func handleClearError(state: inout State) -> Effect<Action> {
        state.errorMessage = nil
        return .none
    }
}
