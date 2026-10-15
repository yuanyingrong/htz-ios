import Foundation

public struct SutraCoverURLResponse: Codable, Equatable {
    public let sutraId: String?
    public let coverId: String?
    public let signedUrl: String?
    public let expireSeconds: Int?
    public let message: String?
}

public struct SutraItemFileURLResponse: Codable, Equatable {
    public let sutraId: String?
    public let sutraItemId: String?
    public let isPaid: Int?
    public let isTrial: Int?
    public let expireSeconds: Int?
    public let signedUrls: SignedURLs?
    
    public struct SignedURLs: Codable, Equatable {
        public let audio: String?
        public let originalLyric: String?
        public let explanationLyric: String?
    }
}
