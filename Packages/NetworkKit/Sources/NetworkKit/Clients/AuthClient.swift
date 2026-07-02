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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let createTimeStr: String
        if let createdAtStr = loginModel.createdAt, let interval = Double(createdAtStr) {
            let date = Date(timeIntervalSince1970: interval)
            createTimeStr = formatter.string(from: date)
        } else {
            createTimeStr = formatter.string(from: Date())
        }
        
        let parameters: [String: Any] = [
            "city": loginModel.wxLoginResp?.city ?? "",
            "country": loginModel.wxLoginResp?.country ?? "",
            "createTime": createTimeStr,
            "group_id": "0",
            "headimgurl": loginModel.wxLoginResp?.headimgurl ?? "",
            "language": "",
            "lastUpdateTime": "",
            "nickname": loginModel.wxLoginResp?.nickname ?? "",
            "note": "",
            "openid": loginModel.wxLoginResp?.openid ?? "",
            "province": loginModel.wxLoginResp?.province ?? "",
            "pwd": "",
            "sex": String(loginModel.wxLoginResp?.sex ?? 0),
            "sign": "",
            "telephone": "",
            "unionid": loginModel.wxLoginResp?.unionid ?? ""
        ]
        
        return networkManager.request(.addUserInfo(parameters: parameters))
    }
}
