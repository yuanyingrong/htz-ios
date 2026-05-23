import Foundation

public struct SutraItem: Codable, Identifiable, Equatable {
    public let id: String
    public let sutraId: String?
    public let title: String?
    public let description: String?
    public let originalLyricId: String?
    public let explanationLyricId: String?
    public let audioId: String?
    public let lesson: Int? // Changed from String? to Int?
    public let playedCount: Int?
    public let duration: Int? // Changed from String? to Int?
    public let createdAt: Int? // Changed from String? to Int?
    public let isVideo: Bool?
    public let audio: String?
    
    public enum CodingKeys: String, CodingKey {
        case id
        case sutraId = "sutra_id"
        case title
        case description = "desc"
        case originalLyricId = "original_lyric_id"
        case explanationLyricId = "explanation_lyric_id"
        case audioId = "audio_id"
        case lesson
        case playedCount = "played_count"
        case duration
        case createdAt = "created_at"
        case isVideo
        case audio
    }
    
    public init(
        id: String,
        sutraId: String? = nil,
        title: String? = nil,
        description: String? = nil,
        originalLyricId: String? = nil,
        explanationLyricId: String? = nil,
        audioId: String? = nil,
        lesson: Int? = nil,
        playedCount: Int? = nil,
        duration: Int? = nil,
        createdAt: Int? = nil,
        isVideo: Bool? = nil,
        audio: String? = nil
    ) {
        self.id = id
        self.sutraId = sutraId
        self.title = title
        self.description = description
        self.originalLyricId = originalLyricId
        self.explanationLyricId = explanationLyricId
        self.audioId = audioId
        self.lesson = lesson
        self.playedCount = playedCount
        self.duration = duration
        self.createdAt = createdAt
        self.isVideo = isVideo
        self.audio = audio
    }
}
