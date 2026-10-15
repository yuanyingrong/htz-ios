import Foundation

public struct APIResponse<T: Codable>: Codable {
    public let code: Int
    public let data: T?
    public let msg: String?

    public init(code: Int, data: T?, msg: String?) {
        self.code = code
        self.data = data
        self.msg = msg
    }
}
