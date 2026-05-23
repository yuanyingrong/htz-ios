import Foundation

public struct APIResponse<T: Codable>: Codable {
    public let code: Int
    public let data: T?
    public let msg: String?
}
