import Foundation
import Combine
import Moya

public protocol AuthClientProtocol {
    func login(code: String) -> AnyPublisher<APIResponse<LoginModel>, NetworkError>
    func syncUserInfo(loginModel: LoginModel) -> AnyPublisher<APIResponse<String>, NetworkError>
}

public class AuthClient: AuthClientProtocol {
    private let networkManager: NetworkManager<HTZAPI>
    
    public init(networkManager: NetworkManager<HTZAPI> = NetworkManager<HTZAPI>()) {
        self.networkManager = networkManager
    }
    
    public func login(code: String) -> AnyPublisher<APIResponse<LoginModel>, NetworkError> {
        return networkManager.request(.login(code: code))
    }
    
    public func syncUserInfo(loginModel: LoginModel) -> AnyPublisher<APIResponse<String>, NetworkError> {
        // Prefer the WeChat payload; fall back to the profile fields of the login response itself.
        let wx = loginModel.wxLoginResp ?? WeChatLoginResponse(
            country: nil,
            unionid: loginModel.unionId,
            city: nil,
            privilege: nil,
            sex: nil,
            province: nil,
            nickname: loginModel.name,
            openid: nil,
            headimgurl: loginModel.avatar
        )
        return Future<APIResponse<String>, NetworkError> { promise in
            _Concurrency.Task {
                await LibraryAPI.syncWeChatProfile(wx)
                promise(.success(APIResponse(code: 200, data: "", msg: nil)))
            }
        }
        .eraseToAnyPublisher()
    }
}
