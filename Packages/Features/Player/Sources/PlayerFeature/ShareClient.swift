import ComposableArchitecture
import Foundation

public enum WeChatScene: Equatable, Sendable {
    case session
    case timeline
    case favorite
}

public struct ShareContent: Equatable, Sendable {
    public var title: String
    public var description: String
    public var url: URL
    public var imageURL: URL?

    public init(title: String, description: String, url: URL, imageURL: URL?) {
        self.title = title
        self.description = description
        self.url = url
        self.imageURL = imageURL
    }

    /// Same landing page Android shares; it bounces into the app (or the store) on the receiving phone.
    public static func episode(id: String, title: String, album: String?, imageURL: URL?) -> ShareContent {
        ShareContent(
            title: title,
            description: album.flatMap { $0.isEmpty ? nil : "黄庭禅《\($0)》" } ?? "黄庭禅",
            url: URL(string: "http://android.neixinchan.com/resources/apk/redirect.html?id=\(id)")!,
            imageURL: imageURL
        )
    }
}

/// Seam for the WeChat SDK, which only exists in the app target (and only on device).
public struct ShareClient: Sendable {
    public var isWeChatInstalled: @Sendable () -> Bool
    public var shareToWeChat: @Sendable (_ content: ShareContent, _ scene: WeChatScene) async -> Bool

    public init(
        isWeChatInstalled: @escaping @Sendable () -> Bool,
        shareToWeChat: @escaping @Sendable (ShareContent, WeChatScene) async -> Bool
    ) {
        self.isWeChatInstalled = isWeChatInstalled
        self.shareToWeChat = shareToWeChat
    }
}

extension ShareClient: DependencyKey {
    public static let liveValue = ShareClient(isWeChatInstalled: { false }, shareToWeChat: { _, _ in false })
    public static let testValue = ShareClient(isWeChatInstalled: { true }, shareToWeChat: { _, _ in true })
}

extension DependencyValues {
    public var shareClient: ShareClient {
        get { self[ShareClient.self] }
        set { self[ShareClient.self] = newValue }
    }
}
