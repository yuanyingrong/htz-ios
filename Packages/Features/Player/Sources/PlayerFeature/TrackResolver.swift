import Foundation
import ComposableArchitecture
import NetworkKit

public struct TrackResolver: Sendable {
    public var resolve: @Sendable (_ sutraId: String, _ itemId: String) async throws -> ResolvedAudio
    public var localFile: @Sendable (_ itemId: String) -> URL?
    public var reportHistory: @Sendable (_ itemId: String, _ position: Int) async -> Void

    public init(
        resolve: @escaping @Sendable (String, String) async throws -> ResolvedAudio,
        localFile: @escaping @Sendable (String) -> URL?,
        reportHistory: @escaping @Sendable (String, Int) async -> Void
    ) {
        self.resolve = resolve
        self.localFile = localFile
        self.reportHistory = reportHistory
    }
}

public enum TrackResolveError: Error, Equatable {
    case accessDenied
    case message(String)
}

extension TrackResolver: DependencyKey {
    public static let liveValue = TrackResolver(
        resolve: { sutraId, itemId in
            let response = try await LibraryAPI.fileURL(sutraId: sutraId, itemId: itemId)
            guard let audio = response.audioURL else {
                throw TrackResolveError.accessDenied
            }
            return ResolvedAudio(
                audioURL: audio,
                originalLyricURL: response.originalLyricURL,
                explanationLyricURL: response.explanationLyricURL
            )
        },
        localFile: { DownloadCenter.shared.localFile(for: $0) },
        reportHistory: { itemId, position in
            await LibraryAPI.reportHistory(itemId: itemId, position: position)
        }
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
