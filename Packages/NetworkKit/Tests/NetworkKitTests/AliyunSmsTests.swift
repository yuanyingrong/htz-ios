import XCTest
@testable import NetworkKit

final class AliyunSmsTests: XCTestCase {
    func testPercentEncodeFollowsAliyunRules() {
        XCTAssertEqual(AliyunSms.percentEncode("a b*c~d/e"), "a%20b%2Ac~d%2Fe")
        XCTAssertEqual(AliyunSms.percentEncode("{\"code\":\"##code##\"}"), "%7B%22code%22%3A%22%23%23code%23%23%22%7D")
    }

        func testSignedQueryIsDeterministicAndSorted() {
        let query = AliyunSms.signedQuery(["Action": "CheckSmsVerifyCode", "PhoneNumber": "13800000000", "VerifyCode": "123456"],
                                          keyId: "id", secret: "secret", timestamp: "2026-10-18T04:00:00Z", nonce: "n-1")
        XCTAssertTrue(query.hasPrefix("AccessKeyId=id&Action=CheckSmsVerifyCode&Format=JSON&PhoneNumber=13800000000"))
        // Computed independently with Python's hmac/hashlib using the same RPC signing rules.
        XCTAssertTrue(query.hasSuffix("&Signature=fz1d8p9qLn2CG2Os8owVo6zV9J0%3D"), query)
        XCTAssertEqual(query, AliyunSms.signedQuery(["Action": "CheckSmsVerifyCode", "PhoneNumber": "13800000000", "VerifyCode": "123456"],
                                                    keyId: "id", secret: "secret", timestamp: "2026-10-18T04:00:00Z", nonce: "n-1"))
    }
}
