import Foundation
import ComposableArchitecture
import NetworkKit

public struct TrackResolver: Sendable {
    public var resolve: @Sendable (_ sutraId: String, _ itemId: String) async throws -> ResolvedAudio
    public var localFile: @Sendable (_ itemId: String) -> URL?
    public var reportHistory: @Sendable (_ itemId: String, _ position: Int) async -> Void
    public var markPlayed: @Sendable (_ itemId: String) async -> Void
    public var rememberTrack: @Sendable (_ track: QueueTrack) -> Void
    public var localLyric: @Sendable (_ itemId: String, _ kind: LyricKind) -> URL?
    public var saveLyric: @Sendable (_ itemId: String, _ kind: LyricKind, _ data: Data) -> Void

    public init(
        resolve: @escaping @Sendable (String, String) async throws -> ResolvedAudio,
        localFile: @escaping @Sendable (String) -> URL?,
        reportHistory: @escaping @Sendable (String, Int) async -> Void,
        markPlayed: @escaping @Sendable (String) async -> Void = { _ in },
        rememberTrack: @escaping @Sendable (QueueTrack) -> Void = { _ in },
        localLyric: @escaping @Sendable (String, LyricKind) -> URL? = { _, _ in nil },
        saveLyric: @escaping @Sendable (String, LyricKind, Data) -> Void = { _, _, _ in }
    ) {
        self.rememberTrack = rememberTrack
        self.localLyric = localLyric
        self.saveLyric = saveLyric
        self.resolve = resolve
        self.localFile = localFile
        self.reportHistory = reportHistory
        self.markPlayed = markPlayed
    }
}

public enum TrackResolveError: Error, Equatable {
    case accessDenied
    case message(String)
}

extension TrackResolver: DependencyKey {
    public static let liveValue = TrackResolver(
        resolve: { sutraId, itemId in
            let urls = try await LibraryAPI.fileURL(sutraId: sutraId, itemId: itemId)
            guard let audio = urls.audioURL else {
                throw TrackResolveError.accessDenied
            }
            return ResolvedAudio(
                audioURL: audio,
                originalLyricURL: urls.originalLyricURL,
                explanationLyricURL: urls.explanationLyricURL
            )
        },
        localFile: { DownloadCenter.shared.localFile(for: $0) },
        reportHistory: { itemId, position in
            await LibraryAPI.reportHistory(itemId: itemId, position: position)
        },
        markPlayed: { await LibraryAPI.incrementPlayedCount(itemId: $0) },
        rememberTrack: { track in
            LibraryAPI.rememberForHistory(
                itemId: track.id, sutraId: track.sutraId, title: track.title, sutraName: track.artist ?? ""
            )
        },
        localLyric: { DownloadCenter.shared.localLyric(for: $0, kind: $1) },
        saveLyric: { DownloadCenter.shared.saveLyric($2, for: $0, kind: $1) }
    )

    public static let testValue = TrackResolver(
        resolve: { _, _ in throw TrackResolveError.message("未配置") },
        localFile: { _ in nil },
        reportHistory: { _, _ in }
    )
}

extension DependencyValues {
    public var trackResolver: TrackResolver {
        get { self[TrackResolver.self] }
        set { self[TrackResolver.self] = newValue }
    }
}
