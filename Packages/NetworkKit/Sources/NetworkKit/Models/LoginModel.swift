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
        wxLoginResp: WeChatLoginResponse?
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
