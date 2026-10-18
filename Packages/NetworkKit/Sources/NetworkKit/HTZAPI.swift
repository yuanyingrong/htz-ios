import Foundation
import Moya

/// A feedback attachment: JPEG image bytes, or a video file on disk.
public enum FeedbackAttachment: Equatable, Sendable {
    case image(Data)
    case video(URL)

    var typeName: String {
        switch self {
        case .image: return "image"
        case .video: return "video"
        }
    }
}

public enum HTZAPI {
    case albums
    case album(id: String)
    case recommendations
    case items(sutraId: String, pageIndex: Int, pageSize: Int)
    case playedCountInc(itemId: String)
    case login(code: String)
    case loginWithUnionid(parameters: [String: Any])
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
    case deleteAllFavorites
    case notifications(pageIndex: Int, pageSize: Int)
    case markNotificationsRead(ids: [String])
    case userInfo(unionid: String)
    case userInfoByPhone(telephone: String)
    case updateUserInfo(parameters: [String: Any])
    case sendSms(telephone: String, unionid: String)
    case secureKey(appName: String)
    case bindTelephone(telephone: String, code: String, unionid: String)
    case putUserMobile(mobile: String)
    case feedbackAdd(parameters: [String: Any])
    case feedbackUpload(attachment: FeedbackAttachment, filename: String)
    case studyDuration(userId: String)
    case studyCompleted(userId: String)
    case reportUsage(records: [[String: Any]])
    case reportStudyCompleted(userId: String, itemIds: [String])
    case checkInUser(id: String)
    case checkInMonth(userId: String, monthDate: String)
}

public enum APIHost {
    public static let main = URL(string: "http://app.htzchina.org:9100/")!
    public static let search = URL(string: "http://app.htzchina.org:9100/search/")!
    public static let personal = URL(string: "http://app.htzchina.org:8082/htz-api-pyservice/api/v1/")!
    public static let checkIn = URL(string: "http://app.htzchina.org:8081/")!
    public static let legacyJSON = URL(string: "http://htzshanghai.top/resources/app_json/")!
    public static let sutraOSS = "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/"
}

public enum WebPage {
    public static let agreement = URL(string: "http://android.neixinchan.com/resources/agreement.html")!
    public static let privacy = URL(string: "http://android.neixinchan.com/resources/privacy.html")!
    public static let tenYears = URL(string: "http://app.htzchina.org/tenyears/#/tenyearsHome")!
    public static let help = URL(string: "http://android.neixinchan.com/resources/apk/help.md")!
    public static let academy = URL(string: "https://htz.org.cn/htsy/purpose/")!
}

extension HTZAPI: TargetType {
    public var baseURL: URL {
        switch self {
        case .search:
            return APIHost.search
        case .addUserInfo, .userInfo, .userInfoByPhone, .updateUserInfo, .sendSms, .secureKey, .bindTelephone, .notifications,
             .markNotificationsRead, .feedbackAdd, .feedbackUpload, .studyDuration, .studyCompleted,
             .reportUsage, .reportStudyCompleted:
            return APIHost.personal
        case .checkInUser, .checkInMonth:
            return APIHost.checkIn
        default:
            return APIHost.main
        }
    }

    public var path: String {
        switch self {
        case .albums: return "get/sutras"
        case .album: return "get/sutra"
        case .recommendations: return "get/recommendations"
        case .items: return "get/sutra/items"
        case .playedCountInc: return "put/sutra/item/playedcount/inc"
        case .login: return "post/login"
        case .loginWithUnionid: return "post/login/unionid"
        case .addUserInfo: return "userinfo/add"
        case .sutraCoverURL: return "get/sutra/cover_url"
        case .sutraItemFileURL: return "get/sutra/item/file_url"
        case .search: return "search"
        case .postListenHistory: return "post/listen/history"
        case .listenHistories: return "get/listen/histories"
        case .deleteListenHistory: return "delete/listen/history"
        case .deleteAllListenHistories: return "delete/listen/histories/all"
        case .addFavorite: return "post/favorite"
        case .favorites: return "get/favorites"
        case .deleteFavorite: return "delete/favorite"
        case .deleteAllFavorites: return "delete/favorites/all"
        case .notifications: return "get/notifications"
        case .markNotificationsRead: return "put/user/notifications"
        case .userInfo: return "userinfo/get"
        case .userInfoByPhone: return "userinfo/getbyphone"
        case .updateUserInfo: return "userinfo/update"
        case .sendSms: return "api/telephone/getSmsCode"
        case .secureKey: return "getaksk"
        case .bindTelephone: return "api/telephone/bindTelephone"
        case .putUserMobile: return "put/user/mobile"
        case .feedbackAdd: return "feedback/add"
        case .feedbackUpload: return "feedback/upload"
        case .studyDuration: return "study/duration"
        case .studyCompleted: return "study/completed"
        case .reportUsage: return "usage/report/batch"
        case .reportStudyCompleted: return "study/completed/report"
        case .checkInUser: return "getById"
        case .checkInMonth: return "getReportInfoListByIdAndMonth"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .userInfo, .userInfoByPhone, .sendSms, .secureKey, .bindTelephone,
             .studyDuration, .studyCompleted, .checkInUser, .checkInMonth:
            return .get
        case .playedCountInc:
            return .put
        default:
            return .post
        }
    }

    public var task: Task {
        switch self {
        case .albums:
            return json(["page_index": 0, "page_size": 500])
        case let .album(id):
            return json(["id": id])
        case let .items(sutraId, pageIndex, pageSize):
            return json(["sutra_id": sutraId, "page_index": pageIndex, "page_size": pageSize])
        case let .playedCountInc(itemId):
            return json(["id": itemId])
        case let .login(code):
            return json(["code": code])
        case let .loginWithUnionid(parameters), let .updateUserInfo(parameters), let .feedbackAdd(parameters),
             let .addUserInfo(parameters):
            return json(parameters)
        case let .sutraCoverURL(sutraId, expireSeconds):
            var params: [String: Any] = ["sutra_id": sutraId]
            if let expireSeconds { params["expire_seconds"] = expireSeconds }
            return json(params)
        case let .sutraItemFileURL(sutraId, sutraItemId, expireSeconds):
            var params: [String: Any] = ["sutra_id": sutraId, "sutra_item_id": sutraItemId]
            if let expireSeconds { params["expire_seconds"] = expireSeconds }
            return json(params)
        case let .search(key, offset, limit):
            return json(["key": key, "output_offset": offset, "max_outputs": limit])
        case let .postListenHistory(itemId, position):
            return json(["sutra_item_id": itemId, "last_position": position])
        case let .listenHistories(pageIndex, pageSize), let .notifications(pageIndex, pageSize):
            return json(["page_index": pageIndex, "page_size": pageSize])
        case let .deleteListenHistory(id), let .deleteFavorite(id):
            return json(["id": id])
        case .favorites:
            return json(["page_index": 0, "page_size": 500])
        case .recommendations, .deleteAllListenHistories, .deleteAllFavorites:
            return .requestPlain
        case let .addFavorite(itemId):
            return json(["sutra_item_id": itemId])
        case let .markNotificationsRead(ids):
            return json(["ids": ids])
        case let .userInfo(unionid):
            return query(["unionid": unionid])
        case let .userInfoByPhone(telephone):
            return query(["telephone": telephone])
        case let .secureKey(appName):
            return query(["appName": appName])
        case let .sendSms(telephone, unionid):
            return query(["telephone": telephone, "unionid": unionid])
        case let .bindTelephone(telephone, code, unionid):
            return query(["telephone": telephone, "code": code, "unionid": unionid])
        case let .putUserMobile(mobile):
            return json(["mobile": mobile])
        case let .feedbackUpload(attachment, filename):
            let file: MultipartFormData
            switch attachment {
            case let .image(data):
                file = MultipartFormData(provider: .data(data), name: "file", fileName: filename, mimeType: "image/jpeg")
            case let .video(url):
                let mime = url.pathExtension.lowercased() == "mov" ? "video/quicktime" : "video/mp4"
                file = MultipartFormData(provider: .file(url), name: "file", fileName: filename, mimeType: mime)
            }
            let type = MultipartFormData(provider: .data(Data(attachment.typeName.utf8)), name: "type")
            return .uploadMultipart([file, type])
        case let .studyDuration(userId), let .studyCompleted(userId):
            return query(["user_id": userId])
        case let .reportUsage(records):
            let body = (try? JSONSerialization.data(withJSONObject: records)) ?? Data("[]".utf8)
            return .requestData(body)
        case let .reportStudyCompleted(userId, itemIds):
            return json(["user_id": userId, "item_ids": itemIds])
        case let .checkInUser(id):
            return query(["id": id])
        case let .checkInMonth(userId, monthDate):
            return query(["userId": userId, "monthDate": monthDate])
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
        Data()
    }

    private func json(_ parameters: [String: Any]) -> Task {
        .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }

    private func query(_ parameters: [String: Any]) -> Task {
        .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
    }
}
