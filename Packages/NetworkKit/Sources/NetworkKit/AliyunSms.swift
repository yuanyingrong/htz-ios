import Foundation
import CryptoKit

/// Aliyun Phone Number Verification (dypnsapi) SMS codes, called straight from the client like Android's
/// `AliyunSmsService`. The AK/SK is fetched from our server (`getaksk`) and never shipped in the app.
enum AliyunSms {
    private static let endpoint = "https://dypnsapi.aliyuncs.com"
    private static let signName = "速通互联验证码"
    private static let templateCode = "100001"

    private actor KeyCache {
        var keys: (id: String, secret: String)?
        var expires = Date.distantPast
        func get() -> (id: String, secret: String)? { Date() < expires ? keys : nil }
        func set(_ keys: (id: String, secret: String)) {
            self.keys = keys
            expires = Date().addingTimeInterval(30 * 60)
        }
    }
    private static let cache = KeyCache()

    static func send(to phone: String, fetchKeys: () async throws -> (String, String)) async throws {
        let response = try await call([
            "Action": "SendSmsVerifyCode",
            "PhoneNumber": phone,
            "SignName": signName,
            "TemplateCode": templateCode,
            "TemplateParam": "{\"code\":\"##code##\",\"min\":\"5\"}",
            "CodeLength": "6",
            "ValidTime": "300",
            "Interval": "60"
        ], fetchKeys: fetchKeys)
        guard response["Code"] as? String == "OK" else {
            throw NetworkError.apiError(message(response, fallback: "发送失败"))
        }
    }

    /// Throws `NetworkError.apiError("验证码错误或已过期")` for a wrong/expired code.
    static func check(phone: String, code: String, fetchKeys: () async throws -> (String, String)) async throws {
        let response = try await call([
            "Action": "CheckSmsVerifyCode",
            "PhoneNumber": phone,
            "VerifyCode": code
        ], fetchKeys: fetchKeys)
        guard response["Code"] as? String == "OK" else {
            throw NetworkError.apiError(message(response, fallback: "验证失败"))
        }
        let model = response["Model"] as? [String: Any]
        guard model?["VerifyResult"] as? String == "PASS" else {
            throw NetworkError.apiError("验证码错误或已过期")
        }
    }

    private static func message(_ response: [String: Any], fallback: String) -> String {
        (response["Message"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? fallback
    }

    private static func call(_ action: [String: String], fetchKeys: () async throws -> (String, String)) async throws -> [String: Any] {
        let keys: (id: String, secret: String)
        if let cached = await cache.get() {
            keys = cached
        } else {
            let fetched = try await fetchKeys()
            keys = (fetched.0, fetched.1)
            await cache.set(keys)
        }
        let query = signedQuery(action, keyId: keys.id, secret: keys.secret)
        guard let url = URL(string: "\(endpoint)?\(query)") else { throw NetworkError.unknown }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (data, _) = try await URLSession.shared.data(for: request)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    static func signedQuery(
        _ action: [String: String],
        keyId: String,
        secret: String,
        timestamp: String = timestamp(),
        nonce: String = UUID().uuidString
    ) -> String {
        var params = action
        params["Format"] = "JSON"
        params["Version"] = "2017-05-25"
        params["AccessKeyId"] = keyId
        params["SignatureMethod"] = "HMAC-SHA1"
        params["Timestamp"] = timestamp
        params["SignatureVersion"] = "1.0"
        params["SignatureNonce"] = nonce

        let canonical = params.sorted { $0.key < $1.key }
            .map { "\(percentEncode($0.key))=\(percentEncode($0.value))" }
            .joined(separator: "&")
        let stringToSign = "GET&\(percentEncode("/"))&\(percentEncode(canonical))"
        let mac = HMAC<Insecure.SHA1>.authenticationCode(for: Data(stringToSign.utf8), using: SymmetricKey(data: Data("\(secret)&".utf8)))
        let signature = Data(mac).base64EncodedString()
        return canonical + "&Signature=" + percentEncode(signature)
    }

    static func percentEncode(_ value: String) -> String {
        let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")
        return value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? value
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: Date())
    }
}
