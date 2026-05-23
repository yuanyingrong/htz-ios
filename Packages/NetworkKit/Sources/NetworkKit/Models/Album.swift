import Foundation

public struct Album: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let imageUrl: String?
    
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageUrl = "cover"
    }
    
    public init(id: String, name: String, imageUrl: String?) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
    }
}
