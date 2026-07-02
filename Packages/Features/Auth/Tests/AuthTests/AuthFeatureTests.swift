import XCTest
import Combine
import ComposableArchitecture
import NetworkKit
@testable import AuthFeature

@MainActor
final class AuthFeatureTests: XCTestCase {
    
    func testWeChatLoginFlowSuccess() async {
        let mockWeChatClient = WeChatClient(
            isInstalled: { true },
            sendAuthRequest: { true }
        )
        
        let mockLoginModel = LoginModel(
            token: "test_token_999",
            name: "Test User",
            id: "user_123",
            unionId: "union_555",
            mobile: nil,
            gender: nil,
            createdAt: "1600000000",
            avatar: nil,
            birthdayYear: nil,
            wxLoginResp: WeChatLoginResponse(
                country: "CN",
                unionid: "union_555",
                city: "Shanghai",
                privilege: [],
                sex: 1,
                province: "Shanghai",
                nickname: "Test User",
                openid: "open_888",
                headimgurl: nil
            )
        )
        
        struct MockAuthClient: AuthClientProtocol {
            let loginResult: Swift.Result<APIResponse<LoginModel>, NetworkError>
            let syncResult: Swift.Result<APIResponse<String>, NetworkError>
            
            func login(code: String) -> AnyPublisher<APIResponse<LoginModel>, NetworkError> {
                return Just(try! loginResult.get())
                    .setFailureType(to: NetworkError.self)
                    .eraseToAnyPublisher()
            }
            
            func syncUserInfo(loginModel: LoginModel) -> AnyPublisher<APIResponse<String>, NetworkError> {
                return Just(try! syncResult.get())
                    .setFailureType(to: NetworkError.self)
                    .eraseToAnyPublisher()
            }
        }
        
        let mockAuthClient = MockAuthClient(
            loginResult: .success(APIResponse(code: 200, data: mockLoginModel, msg: "success")),
            syncResult: .success(APIResponse(code: 200, data: "success", msg: "success"))
        )
        
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.weChatClient = mockWeChatClient
            $0.authClient = mockAuthClient
        }
        
        AuthManager.shared.logout()
        
        // 1. WeChat login button tapped
        await store.send(.wechatLoginTapped) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        
        // 2. Receive auth code from WeChat callback
        await store.send(.receiveAuthCode("wechat_code_abc"))
        
        // 3. Receive token and login model response
        await store.receive(\.tokenResponse(.success(mockLoginModel)))
        
        // Check that tokens were saved
        XCTAssertEqual(AuthManager.shared.token, "test_token_999")
        XCTAssertEqual(AuthManager.shared.unionid, "union_555")
        
        // 4. Sync profile information
        await store.receive(\.syncResponse(.success(true))) {
            $0.isLoading = false
            $0.isLoggedIn = true
        }
    }
    
    func testWeChatNotInstalled() async {
        let mockWeChatClient = WeChatClient(
            isInstalled: { false },
            sendAuthRequest: { false }
        )
        
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.weChatClient = mockWeChatClient
        }
        
        await store.send(.wechatLoginTapped) {
            $0.isLoading = false
            $0.errorMessage = "您的设备未安装微信"
        }
    }
    
    func testLogoutFlow() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        }
        
        AuthManager.shared.token = "dummy"
        store.dependencies.authClient = MockAuthClientEmpty()
        
        await store.send(.logout) {
            $0.isLoggedIn = false
            $0.isLoading = false
            $0.errorMessage = nil
        }
        
        XCTAssertNil(AuthManager.shared.token)
    }
}

private struct MockAuthClientEmpty: AuthClientProtocol {
    func login(code: String) -> AnyPublisher<APIResponse<LoginModel>, NetworkError> {
        Empty().eraseToAnyPublisher()
    }
    func syncUserInfo(loginModel: LoginModel) -> AnyPublisher<APIResponse<String>, NetworkError> {
        Empty().eraseToAnyPublisher()
    }
}
