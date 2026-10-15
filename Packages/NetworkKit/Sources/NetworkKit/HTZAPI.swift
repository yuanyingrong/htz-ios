import Foundation
import Moya

public enum HTZAPI {
    case albums
    case items(sutraId: String, pageIndex: Int, pageSize: Int)
    case login(code: String)
    case addUserInfo(parameters: [String: Any])
    case sutraCoverURL(sutraId: String, expireSeconds: Int?)
    case sutraItemFileURL(sutraId: String, sutraItemId: String, expireSeconds: Int?)
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
        case .sutraCoverURL:
            return "get/sutra/cover_url"
        case .sutraItemFileURL:
            return "get/sutra/item/file_url"
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
        case let .sutraCoverURL(sutraId, expireSeconds):
            var params: [String: Any] = ["sutra_id": sutraId]
            if let expire = expireSeconds {
                params["expire_seconds"] = expire
            }
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case let .sutraItemFileURL(sutraId, sutraItemId, expireSeconds):
            var params: [String: Any] = [
                "sutra_id": sutraId,
                "sutra_item_id": sutraItemId
            ]
            if let expire = expireSeconds {
                params["expire_seconds"] = expire
            }
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
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
