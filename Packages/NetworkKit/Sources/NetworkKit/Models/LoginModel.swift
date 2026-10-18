import Foundation

public struct LoginModel: Codable, Equatable {
    public let token: String?
    public let name: String?
    public let id: String?
    public let unionId: String?
    public let mobile: String?
    public let gender: String?
    public let createdAt: String?
    public let avatar: String?
    public let birthdayYear: String?
    public let wxLoginResp: WeChatLoginResponse?
    public let appleUserId: String?

    public init(
        token: String?,
        name: String?,
        id: String?,
        unionId: String?,
        mobile: String?,
        gender: String?,
        createdAt: String?,
        avatar: String?,
        birthdayYear: String?,
        wxLoginResp: WeChatLoginResponse?,
        appleUserId: String? = nil
    ) {
        self.token = token
        self.name = name
        self.id = id
        self.unionId = unionId
        self.mobile = mobile
        self.gender = gender
        self.createdAt = createdAt
        self.avatar = avatar
        self.birthdayYear = birthdayYear
        self.wxLoginResp = wxLoginResp
        self.appleUserId = appleUserId
    }
    
    /// `NetworkManager` decodes with `.convertFromSnakeCase`, which rewrites `union_id` to `unionId`
    /// *before* matching `CodingKeys` — so the explicit snake_case raw values below never match there
    /// and `unionId` / `wxLoginResp` silently came back nil. Accept both spellings.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleKey.self)
        func value<T: Decodable>(_ type: T.Type, _ names: String...) -> T? {
            for name in names {
                if let key = FlexibleKey(stringValue: name),
                   let decoded = try? container.decodeIfPresent(T.self, forKey: key) {
                    return decoded
                }
            }
            return nil
        }
        token = value(String.self, "token")
        name = value(String.self, "name")
        id = value(String.self, "id")
        unionId = value(String.self, "union_id", "unionId")
        mobile = value(String.self, "mobile")
        gender = value(String.self, "gender")
        createdAt = value(String.self, "created_at", "createdAt")
        avatar = value(String.self, "avatar")
        birthdayYear = value(String.self, "birthday_year", "birthdayYear")
        wxLoginResp = value(WeChatLoginResponse.self, "wx_login_resp", "wxLoginResp")
        appleUserId = value(String.self, "apple_user_id", "appleUserId")
    }

    private struct FlexibleKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public enum CodingKeys: String, CodingKey {
        case token
        case name
        case id
        case unionId = "union_id"
        case mobile
        case gender
        case createdAt = "created_at"
        case avatar
        case birthdayYear = "birthday_year"
        case wxLoginResp = "wx_login_resp"
        case appleUserId = "apple_user_id"
    }
}

public struct WeChatLoginResponse: Codable, Equatable {
    public let country: String?
    public let unionid: String?
    public let city: String?
    public let privilege: [String]?
    public let sex: Int?
    public let province: String?
    public let nickname: String?
    public let openid: String?
    public let headimgurl: String?
    
    public init(
        country: String?,
        unionid: String?,
        city: String?,
        privilege: [String]?,
        sex: Int?,
        province: String?,
        nickname: String?,
        openid: String?,
        headimgurl: String?
    ) {
        self.country = country
        self.unionid = unionid
        self.city = city
        self.privilege = privilege
        self.sex = sex
        self.province = province
        self.nickname = nickname
        self.openid = openid
        self.headimgurl = headimgurl
    }
}
