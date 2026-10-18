import ComposableArchitecture
import Foundation

public struct DownloadClient: Sendable {
    public var updates: @Sendable () -> AsyncStream<[DownloadRecord]>
    public var download: @Sendable (DownloadRequest) -> Void
    public var pause: @Sendable (_ itemId: String) -> Void
    public var resume: @Sendable (_ itemId: String) -> Void
    public var cancel: @Sendable (_ itemId: String) -> Void
    public var delete: @Sendable (_ itemIds: [String]) -> Void
    public var isDownloaded: @Sendable (_ itemId: String) -> Bool

    public init(
        updates: @escaping @Sendable () -> AsyncStream<[DownloadRecord]>,
        download: @escaping @Sendable (DownloadRequest) -> Void,
        pause: @escaping @Sendable (String) -> Void,
        resume: @escaping @Sendable (String) -> Void,
        cancel: @escaping @Sendable (String) -> Void,
        delete: @escaping @Sendable ([String]) -> Void,
        isDownloaded: @escaping @Sendable (String) -> Bool
    ) {
        self.updates = updates
        self.download = download
        self.pause = pause
        self.resume = resume
        self.cancel = cancel
        self.delete = delete
        self.isDownloaded = isDownloaded
    }
}

extension DownloadClient: DependencyKey {
    public static let liveValue = DownloadClient(
        updates: { DownloadCenter.shared.updates() },
        download: { DownloadCenter.shared.download($0) },
        pause: { DownloadCenter.shared.pause(itemId: $0) },
        resume: { DownloadCenter.shared.resume(itemId: $0) },
        cancel: { DownloadCenter.shared.cancel(itemId: $0) },
        delete: { DownloadCenter.shared.delete(itemIds: $0) },
        isDownloaded: { DownloadCenter.shared.localFile(for: $0) != nil }
    )

    public static let testValue = DownloadClient(
        updates: { AsyncStream { $0.finish() } },
        download: { _ in },
        pause: { _ in },
        resume: { _ in },
        cancel: { _ in },
        delete: { _ in },
        isDownloaded: { _ in false }
    )
}

extension DependencyValues {
    public var downloads: DownloadClient {
        get { self[DownloadClient.self] }
        set { self[DownloadClient.self] = newValue }
    }
}
