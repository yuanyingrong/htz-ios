import Foundation

public struct MediaFileURLs: Equatable, Sendable {
    public var audioURL: URL?
    public var originalLyricURL: URL?
    public var explanationLyricURL: URL?

    public init(audioURL: URL?, originalLyricURL: URL? = nil, explanationLyricURL: URL? = nil) {
        self.audioURL = audioURL
        self.originalLyricURL = originalLyricURL
        self.explanationLyricURL = explanationLyricURL
    }
}

public struct Recommendation: Equatable, Identifiable, Sendable {
    public var id: String { sutraId }
    public var sutraId: String
    public var name: String
    public var imageUrl: String?
    public var description: String

    public init(sutraId: String, name: String, imageUrl: String?, description: String) {
        self.sutraId = sutraId
        self.name = name
        self.imageUrl = imageUrl
        self.description = description
    }
}

public struct AlbumPurchase: Equatable, Sendable {
    public var isPaid: Bool
    public var isPurchased: Bool
    public var paidUrl: String?

    public init(isPaid: Bool, isPurchased: Bool, paidUrl: String?) {
        self.isPaid = isPaid
        self.isPurchased = isPurchased
        self.paidUrl = paidUrl
    }
}

public struct SearchHit: Equatable, Identifiable, Sendable {
    public var id: String
    public var sutraTitle: String
    public var title: String
    public var time: String
    public var content: String
    public var lrcType: String

    public init(id: String, sutraTitle: String, title: String, time: String, content: String, lrcType: String) {
        self.id = id
        self.sutraTitle = sutraTitle
        self.title = title
        self.time = time
        self.content = content
        self.lrcType = lrcType
    }

    /// Seconds into the track where the matched lyric line starts (`mm:ss`, `mm:ss.xx` or `hh:mm:ss`).
    public var startSeconds: Double {
        let parts = time.trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
            .split(separator: ":")
            .compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
        return parts.reduce(0) { $0 * 60 + $1 }
    }
}

public struct FavoriteItem: Equatable, Identifiable, Sendable {
    public var id: String
    public var serverId: String
    public var sutraItemId: String
    public var sutraId: String
    public var title: String
    public var sutraName: String
    public var cover: String

    public init(id: String, serverId: String, sutraItemId: String, sutraId: String, title: String, sutraName: String, cover: String) {
        self.id = id
        self.serverId = serverId
        self.sutraItemId = sutraItemId
        self.sutraId = sutraId
        self.title = title
        self.sutraName = sutraName
        self.cover = cover
    }

    public var itemId: String { sutraItemId.isEmpty ? id : sutraItemId }
}

public struct ListenHistoryItem: Equatable, Identifiable, Sendable {
    public var id: String
    public var sutraItemId: String
    public var sutraId: String
    public var title: String
    public var sutraName: String
    public var cover: String
    public var lastPosition: Int

    public init(id: String, sutraItemId: String, sutraId: String, title: String, sutraName: String, cover: String, lastPosition: Int) {
        self.id = id
        self.sutraItemId = sutraItemId
        self.sutraId = sutraId
        self.title = title
        self.sutraName = sutraName
        self.cover = cover
        self.lastPosition = lastPosition
    }

    public var itemId: String { sutraItemId.isEmpty ? id : sutraItemId }
    public var lastPositionSeconds: Int { MediaTime.seconds(lastPosition) }
}

public struct NoticeItem: Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var message: String
    public var createdAt: String
    public var isRead: Bool

    public init(id: String, title: String, message: String, createdAt: String = "", isRead: Bool) {
        self.id = id
        self.title = title
        self.message = message
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

public struct UserProfile: Equatable, Sendable {
    public var nickname: String
    public var avatar: String
    public var signature: String
    public var mobile: String
    public var unionid: String
    public var sex: Int
    public var province: String
    public var city: String

    public init(
        nickname: String = "",
        avatar: String = "",
        signature: String = "",
        mobile: String = "",
        unionid: String = "",
        sex: Int = 0,
        province: String = "",
        city: String = ""
    ) {
        self.nickname = nickname
        self.avatar = avatar
        self.signature = signature
        self.mobile = mobile
        self.unionid = unionid
        self.sex = sex
        self.province = province
        self.city = city
    }

    public var sexText: String {
        switch sex {
        case 1: return "男"
        case 2: return "女"
        default: return "未设置"
        }
    }

    public var region: String {
        [province, city].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

/// Raw study data from the personal server: per-day play time and completed lesson count.
public struct StudyRecord: Equatable, Sendable {
    public var durations: [String: Int]
    public var completedLessons: Int

    public init(durations: [String: Int] = [:], completedLessons: Int = 0) {
        self.durations = durations
        self.completedLessons = completedLessons
    }
}

public enum MediaTime {
    /// Server positions and durations arrive in either milliseconds or seconds; values ≥ 100 000 are milliseconds.
    public static func seconds(_ value: Int) -> Int {
        value >= 100_000 ? value / 1000 : value
    }

    public static func clock(_ seconds: Int) -> String {
        guard seconds > 0 else { return "00:00" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remain = seconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remain)
        }
        return String(format: "%02d:%02d", minutes, remain)
    }

    public static func ossURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") { return URL(string: path) }
        return URL(string: APIHost.sutraOSS + path)
    }
}
