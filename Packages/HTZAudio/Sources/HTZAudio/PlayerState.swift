import Foundation

public struct PlayerItem: Codable, Equatable, Sendable {
    public let id: String
    public let sutraId: String
    public let url: URL
    public let title: String
    public let artist: String?
    public let imageUrl: URL?
    public let originalLyricURL: URL?
    public let explanationLyricURL: URL?

    public init(
        id: String,
        url: URL,
        title: String,
        artist: String?,
        imageUrl: URL?,
        sutraId: String = "",
        originalLyricURL: URL? = nil,
        explanationLyricURL: URL? = nil
    ) {
        self.id = id
        self.sutraId = sutraId
        self.url = url
        self.title = title
        self.artist = artist
        self.imageUrl = imageUrl
        self.originalLyricURL = originalLyricURL
        self.explanationLyricURL = explanationLyricURL
    }
}

public struct PlayerState: Codable, Equatable, Sendable {
    public var currentItem: PlayerItem?
    public var isPlaying: Bool
    public var currentTime: Double // In seconds
    public var duration: Double   // In seconds
    public var rate: Double
    public var didFinish: Bool
    public var error: String?
    
    public init(
        currentItem: PlayerItem? = nil,
        isPlaying: Bool = false,
        currentTime: Double = 0,
        duration: Double = 0,
        rate: Double = 1,
        didFinish: Bool = false,
        error: String? = nil
    ) {
        self.currentItem = currentItem
        self.isPlaying = isPlaying
        self.currentTime = currentTime
        self.duration = duration
        self.rate = rate
        self.didFinish = didFinish
        self.error = error
    }
    
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
}
