import XCTest
import Moya
@testable import NetworkKit

final class WeChatProfileSyncTests: XCTestCase {
    func testAddUserInfoTargetsPersonalServerLikeAndroid() {
        let target = HTZAPI.addUserInfo(parameters: [:])
        XCTAssertEqual(target.baseURL, APIHost.personal)
        XCTAssertEqual(target.path, "userinfo/add")
        XCTAssertEqual(target.method, .post)
    }

    func testUserInfoParametersCarryNicknameAndAvatar() {
        let wx = WeChatLoginResponse(country: "CN", unionid: "u1", city: "SH", privilege: [], sex: 2, province: "SH", nickname: "小明", openid: "o1", headimgurl: "https://thirdwx.qlogo.cn/a/0")
        let params = LibraryAPI.userInfoParameters(wx)
        XCTAssertEqual(params["nickname"] as? String, "小明")
        XCTAssertEqual(params["headimgurl"] as? String, "https://thirdwx.qlogo.cn/a/0")
        XCTAssertEqual(params["unionid"] as? String, "u1")
        XCTAssertEqual(params["sex"] as? String, "2")
    }
}
