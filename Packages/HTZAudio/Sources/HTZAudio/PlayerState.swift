import Foundation

public struct PlayerItem: Codable, Equatable, Sendable {
    public let id: String
    public let url: URL
    public let title: String
    public let artist: String?
    public let imageUrl: URL? // For lock screen / UI
    
    public init(id: String, url: URL, title: String, artist: String?, imageUrl: URL?) {
        self.id = id
        self.url = url
        self.title = title
        self.artist = artist
        self.imageUrl = imageUrl
    }
}

public struct PlayerState: Codable, Equatable, Sendable {
    public var currentItem: PlayerItem?
    public var isPlaying: Bool
    public var currentTime: Double // In seconds
    public var duration: Double   // In seconds
    public var error: String?
    
    public init(
        currentItem: PlayerItem? = nil,
        isPlaying: Bool = false,
        currentTime: Double = 0,
        duration: Double = 0,
        error: String? = nil
    ) {
        self.currentItem = currentItem
        self.isPlaying = isPlaying
        self.currentTime = currentTime
        self.duration = duration
        self.error = error
    }
    
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
}
