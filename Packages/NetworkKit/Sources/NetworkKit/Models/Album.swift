import Foundation

public struct Album: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let imageUrl: String?
    public let description: String?
    public let isPaid: Bool
    /// Server value in fen (分), e.g. 9900 = ¥99.00.
    public let price: Double
    public var priceInYuan: Double { price / 100 }
    public let isPurchased: Bool
    public let paidUrl: String?

    public enum CodingKeys: String, CodingKey {
        case id
        case albumId
        case name
        case albumName
        case cover
        case imageUrl
        case description
        case isPaid
        case price
        case isPurchased
        case paidUrl
    }

    public init(
        id: String,
        name: String,
        imageUrl: String?,
        description: String? = nil,
        isPaid: Bool = false,
        price: Double = 0,
        isPurchased: Bool = false,
        paidUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.description = description
        self.isPaid = isPaid
        self.price = price
        self.isPurchased = isPurchased
        self.paidUrl = paidUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.string(container, .id, .albumId) ?? UUID().uuidString
        name = Self.string(container, .name, .albumName) ?? ""
        imageUrl = Self.string(container, .cover, .imageUrl)
        description = Self.string(container, .description)
        isPaid = Self.bool(container, .isPaid)
        price = Self.double(container, .price)
        isPurchased = Self.bool(container, .isPurchased)
        paidUrl = Self.string(container, .paidUrl)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageUrl, forKey: .cover)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isPaid, forKey: .isPaid)
        try container.encode(price, forKey: .price)
        try container.encode(isPurchased, forKey: .isPurchased)
        try container.encodeIfPresent(paidUrl, forKey: .paidUrl)
    }

    public func replacingImageUrl(_ imageUrl: String?) -> Album {
        Album(
            id: id,
            name: name,
            imageUrl: imageUrl,
            description: description,
            isPaid: isPaid,
            price: price,
            isPurchased: isPurchased,
            paidUrl: paidUrl
        )
    }

    private static func string(_ container: KeyedDecodingContainer<CodingKeys>, _ keys: CodingKeys...) -> String? {
        for key in keys {
            if let value = try? container.decode(String.self, forKey: key), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func bool(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Bool {
        if let value = try? container.decode(Bool.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return value != 0 }
        if let value = try? container.decode(String.self, forKey: key) {
            return value == "1" || value.lowercased() == "true"
        }
        return false
    }

    private static func double(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return Double(value) }
        if let value = try? container.decode(String.self, forKey: key), let number = Double(value) { return number }
        return 0
    }
}
