import ComposableArchitecture
import Foundation
import NetworkKit

/// Lets any feature hand a queue to the shared player without holding its store.
public struct PlaybackClient: Sendable {
    public var play: @Sendable (_ tracks: [QueueTrack], _ startIndex: Int, _ presentPlayer: Bool, _ startPosition: Double) async -> Void

    public init(play: @escaping @Sendable ([QueueTrack], Int, Bool, Double) async -> Void) {
        self.play = play
    }
}

extension PlaybackClient: DependencyKey {
    public static let liveValue = PlaybackClient { tracks, index, present, position in
        PlayerRelay.shared.play(tracks: tracks, startIndex: index, presentPlayer: present, startPosition: position)
    }

    public static let testValue = PlaybackClient { _, _, _, _ in }
}

extension DependencyValues {
    public var playback: PlaybackClient {
        get { self[PlaybackClient.self] }
        set { self[PlaybackClient.self] = newValue }
    }
}

public extension QueueTrack {
    init(item: SutraItem, sutraId: String, albumName: String, cover: String?) {
        self.init(
            id: item.id,
            sutraId: item.sutraId ?? sutraId,
            title: item.title ?? "",
            artist: albumName,
            imageUrl: cover.flatMap(URL.init(string:)),
            originalLyricURL: item.originalLyricFileURL,
            explanationLyricURL: item.explanationLyricFileURL,
            duration: item.durationSeconds > 0 ? item.durationSeconds : nil
        )
    }

    init(history: ListenHistoryItem) {
        self.init(
            id: history.itemId,
            sutraId: history.sutraId,
            title: history.title,
            artist: history.sutraName,
            imageUrl: MediaTime.ossURL(history.cover)
        )
    }

    init(favorite: FavoriteItem) {
        self.init(
            id: favorite.itemId,
            sutraId: favorite.sutraId,
            title: favorite.title,
            artist: favorite.sutraName,
            imageUrl: MediaTime.ossURL(favorite.cover)
        )
    }

    init(download: DownloadRecord) {
        self.init(
            id: download.itemId,
            sutraId: download.sutraId,
            title: download.title,
            artist: download.albumName,
            imageUrl: download.imageURL.flatMap(URL.init(string:))
        )
    }
}
