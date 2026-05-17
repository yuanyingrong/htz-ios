import Foundation

public struct Banner: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String?
    public let description: String?
    public let imageUrl: String?
    public let sort: String?
    
    public enum CodingKeys: String, CodingKey {
        case id = "sutra_id"
        case name = "sutra_name"
        case description = "sutra_desc"
        case imageUrl = "sutra_cover"
        case sort
    }
    
    public init(id: String, name: String? = nil, description: String? = nil, imageUrl: String? = nil, sort: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.sort = sort
    }
}
