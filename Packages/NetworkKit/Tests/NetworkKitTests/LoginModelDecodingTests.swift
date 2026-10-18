import XCTest
@testable import NetworkKit

final class LoginModelDecodingTests: XCTestCase {
    private let json = """
    {"code":200,"data":{"token":"t1","name":"小明","id":"7","union_id":"u1","mobile":"","gender":"1",
     "created_at":"1700000000","avatar":"https://a/b.png","birthday_year":"1990",
     "wx_login_resp":{"country":"CN","unionid":"u1","city":"SH","privilege":[],"sex":1,"province":"SH",
     "nickname":"小明","openid":"o1","headimgurl":"https://thirdwx.qlogo.cn/a/0"}},"msg":"ok"}
    """.data(using: .utf8)!

    private func check(_ decoder: JSONDecoder, file: StaticString = #filePath, line: UInt = #line) throws {
        let response = try decoder.decode(APIResponse<LoginModel>.self, from: json)
        let model = try XCTUnwrap(response.data, file: file, line: line)
        XCTAssertEqual(model.token, "t1", file: file, line: line)
        XCTAssertEqual(model.unionId, "u1", file: file, line: line)
        XCTAssertEqual(model.wxLoginResp?.nickname, "小明", file: file, line: line)
        XCTAssertEqual(model.wxLoginResp?.headimgurl, "https://thirdwx.qlogo.cn/a/0", file: file, line: line)
        XCTAssertEqual(model.createdAt, "1700000000", file: file, line: line)
    }

    /// The app decodes with `.convertFromSnakeCase` (see `NetworkManager`).
    func testDecodesWithSnakeCaseStrategyUsedByNetworkManager() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        try check(decoder)
    }

    func testDecodesWithDefaultStrategy() throws {
        try check(JSONDecoder())
    }
}
