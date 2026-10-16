import Foundation
import Moya

public enum HTZAPI {
    case albums
    case items(sutraId: String, pageIndex: Int, pageSize: Int)
    case login(code: String)
    case addUserInfo(parameters: [String: Any])
    case sutraCoverURL(sutraId: String, expireSeconds: Int?)
    case sutraItemFileURL(sutraId: String, sutraItemId: String, expireSeconds: Int?)
    case search(key: String, offset: Int, limit: Int)
    case postListenHistory(itemId: String, position: Int)
    case listenHistories(pageIndex: Int, pageSize: Int)
    case deleteListenHistory(id: String)
    case deleteAllListenHistories
    case addFavorite(itemId: String)
    case favorites
    case deleteFavorite(id: String)
    case notifications(pageIndex: Int, pageSize: Int)
    case markNotificationsRead(ids: [String])
    case userInfo(unionid: String)
    case updateUserInfo(parameters: [String: Any])
    case sendSms(telephone: String, unionid: String)
    case bindTelephone(telephone: String, code: String, unionid: String)
    case putUserMobile(mobile: String)
    case feedbackAdd(parameters: [String: Any])
    case feedbackUpload(data: Data, filename: String)
}

private enum APIHost {
    static let main = URL(string: "http://39.105.174.143:9100/")!
    static let search = URL(string: "http://39.105.174.143:9100/search/")!
    static let personal = URL(string: "http://app.htzchina.org:8082/htz-api-pyservice/api/v1/")!
    static let legacyJSON = URL(string: "http://htzshanghai.top/resources/app_json/")!
}

extension HTZAPI: TargetType {
    public var baseURL: URL {
        switch self {
        case .addUserInfo:
            return APIHost.legacyJSON
        case .search:
            return APIHost.search
        case .userInfo, .updateUserInfo, .sendSms, .bindTelephone, .notifications, .markNotificationsRead, .feedbackAdd, .feedbackUpload:
            return APIHost.personal
        default:
            return APIHost.main
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
        case .search:
            return "search"
        case .postListenHistory:
            return "post/listen/history"
        case .listenHistories:
            return "get/listen/histories"
        case .deleteListenHistory:
            return "delete/listen/history"
        case .deleteAllListenHistories:
            return "delete/listen/histories/all"
        case .addFavorite:
            return "post/favorite"
        case .favorites:
            return "get/favorites"
        case .deleteFavorite:
            return "delete/favorite"
        case .notifications:
            return "get/notifications"
        case .markNotificationsRead:
            return "put/user/notifications"
        case .userInfo:
            return "userinfo/get"
        case .updateUserInfo:
            return "userinfo/update"
        case .sendSms:
            return "api/telephone/getSmsCode"
        case .bindTelephone:
            return "api/telephone/bindTelephone"
        case .putUserMobile:
            return "put/user/mobile"
        case .feedbackAdd:
            return "feedback/add"
        case .feedbackUpload:
            return "feedback/upload"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .addUserInfo, .userInfo, .sendSms, .bindTelephone:
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
        case let .search(key, offset, limit):
            return .requestParameters(parameters: [
                "key": key,
                "output_offset": offset,
                "max_outputs": limit
            ], encoding: JSONEncoding.default)
        case let .postListenHistory(itemId, position):
            return .requestParameters(parameters: [
                "sutra_item_id": itemId,
                "last_position": position
            ], encoding: JSONEncoding.default)
        case let .listenHistories(pageIndex, pageSize), let .notifications(pageIndex, pageSize):
            return .requestParameters(parameters: [
                "page_index": pageIndex,
                "page_size": pageSize
            ], encoding: JSONEncoding.default)
        case let .deleteListenHistory(id), let .deleteFavorite(id):
            return .requestParameters(parameters: ["id": id], encoding: JSONEncoding.default)
        case .deleteAllListenHistories, .favorites:
            return .requestPlain
        case let .addFavorite(itemId):
            return .requestParameters(parameters: ["sutra_item_id": itemId], encoding: JSONEncoding.default)
        case let .markNotificationsRead(ids):
            return .requestParameters(parameters: ["ids": ids], encoding: JSONEncoding.default)
        case let .userInfo(unionid):
            return .requestParameters(parameters: ["unionid": unionid], encoding: URLEncoding.queryString)
        case let .updateUserInfo(parameters), let .feedbackAdd(parameters):
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .sendSms(telephone, unionid):
            return .requestParameters(parameters: ["telephone": telephone, "unionid": unionid], encoding: URLEncoding.queryString)
        case let .bindTelephone(telephone, code, unionid):
            return .requestParameters(parameters: [
                "telephone": telephone,
                "code": code,
                "unionid": unionid
            ], encoding: URLEncoding.queryString)
        case let .putUserMobile(mobile):
            return .requestParameters(parameters: ["mobile": mobile], encoding: JSONEncoding.default)
        case let .feedbackUpload(data, filename):
            let file = MultipartFormData(provider: .data(data), name: "file", fileName: filename, mimeType: "image/jpeg")
            let type = MultipartFormData(provider: .data(Data("image".utf8)), name: "type")
            return .uploadMultipart([file, type])
        }
    }
    
    public var headers: [String: String]? {
        var headers: [String: String] = [:]
        if case .feedbackUpload = self {
        } else {
            headers["Content-Type"] = "application/json"
        }
        if let token = AuthManager.shared.token {
            headers["token"] = token
        }
        return headers
    }
    
    public var sampleData: Data {
        return Data()
    }
}
