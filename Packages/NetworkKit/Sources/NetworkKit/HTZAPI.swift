import Foundation
import Moya

public enum HTZAPI {
    case albums
    case items(sutraId: String, pageIndex: Int, pageSize: Int)
    case login(code: String)
    case addUserInfo(parameters: [String: Any])
}

extension HTZAPI: TargetType {
    public var baseURL: URL {
        switch self {
        case .addUserInfo:
            return URL(string: "http://htzshanghai.top/resources/app_json/")!
        default:
            return URL(string: "http://39.105.174.143:9100/")!
        }
    }
    
    public var path: String {
        switch self {
        case .albums:
            return "get/sutras"
        case .items:
            return "get/sutra/items"
        case .login:
            return "post/login"
        case .addUserInfo:
            return "userinfo/add.json"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .addUserInfo:
            return .get
        default:
            return .post
        }
    }
    
    public var task: Task {
        switch self {
        case .albums:
            return .requestParameters(parameters: ["page_index": 0, "page_size": 500], encoding: JSONEncoding.default)
        case let .items(sutraId, pageIndex, pageSize):
            return .requestParameters(parameters: [
                "sutra_id": sutraId,
                "page_index": pageIndex,
                "page_size": pageSize
            ], encoding: JSONEncoding.default)
        case let .login(code):
            return .requestParameters(parameters: ["code": code], encoding: JSONEncoding.default)
        case let .addUserInfo(parameters):
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        }
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        if let token = AuthManager.shared.token {
            headers["token"] = token
        }
        return headers
    }
    
    public var sampleData: Data {
        return Data()
    }
}
