import Foundation
import ComposableArchitecture
import HTZAudio
import NetworkKit
import SwiftUI

@Reducer
public struct PlayerFeature {
    @ObservableState
    public struct State: Equatable {
        public var queue: [QueueTrack] = []
        public var index: Int = 0
        public var currentItem: PlayerItem?
        public var isPlaying: Bool = false
        public var currentTime: Double = 0
        public var duration: Double = 0
        public var rate: Double = 1
        public var didFinish: Bool = false
        public var isResolving: Bool = false
        public var error: String?
        public var alertMessage: String?
        public var showFullPlayer: Bool = false
        public var lyricKind: LyricKind = .explanation
        public var lyricLines: [LyricLine] = []
        public var playMode: PlayMode = PlayModeStore.current
        public var isFavorite: Bool = false
        public var favoriteServerId: String?
        public var resumeSeek: Double?
        public var progress: Double {
            guard duration > 0 else { return 0 }
            return currentTime / duration
        }
        public var activeLyricIndex: Int? {
            guard !lyricLines.isEmpty else { return nil }
            let ms = Int(currentTime * 1000)
            return lyricLines.lastIndex { $0.millisecond <= ms }
        }
        public init() {}
    }

    public enum Action: Equatable {
        case playQueue(tracks: [QueueTrack], startIndex: Int, startPosition: Double)
        case playButtonTapped
        case pauseButtonTapped
        case nextTrack
        case previousTrack
        case trackDidFinish
        case seek(Double)
        case setRate(Double)
        case playerStateUpdated(PlayerState)
        case subscribeToPlayerState
        case remoteCommand(RemoteCommand)
        case trackResolved(index: Int, audio: ResolvedAudio)
        case playbackDenied(revertTo: Int?)
        case playbackFailed(String)
        case lyricsLoaded([LyricLine])
        case setLyricKind(LyricKind)
        case openFullPlayer
        case closeFullPlayer
        case clearAlert
        case downloadCurrent
        case selectTrack(Int)
        case cyclePlayMode
        case refreshFavoriteStatus
        case favoriteStatusLoaded(isFavorite: Bool, serverId: String?)
        case toggleFavorite
        case favoriteToggled(isFavorite: Bool, serverId: String?)
    }

    @Dependency(\.playerClient) var playerClient
    @Dependency(\.trackResolver) var trackResolver
    @Dependency(\.nowPlayingClient) var nowPlayingClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .playQueue(tracks, startIndex, startPosition):
                state.queue = tracks
                state.index = min(max(0, startIndex), max(tracks.count - 1, 0))
                state.alertMessage = nil
                state.lyricLines = []
                state.resumeSeek = startPosition > 1 ? startPosition : nil
                state.isFavorite = false
                state.favoriteServerId = nil
                return .merge(
                    playCurrent(state: &state, revertTo: nil),
                    .send(.refreshFavoriteStatus)
                )

            case .playButtonTapped:
                return .run { _ in await playerClient.resume() }

            case .pauseButtonTapped:
                let itemId = state.currentItem?.id ?? ""
                let position = Int(state.currentTime)
                return .merge(
                    .run { _ in await playerClient.pause() },
                    .run { _ in await trackResolver.reportHistory(itemId, position) }
                )

            case .nextTrack:
                return move(state: &state, auto: false, forward: true)

            case .previousTrack:
                if state.currentTime > 3 {
                    state.currentTime = 0
                    return .run { _ in await playerClient.seek(0) }
                }
                return move(state: &state, auto: false, forward: false)

            case .trackDidFinish:
                return move(state: &state, auto: true, forward: true)

            case let .seek(seconds):
                return .run { _ in await playerClient.seek(seconds) }

            case let .setRate(rate):
                state.rate = rate
                return .run { _ in await playerClient.setRate(rate) }

            case let .playerStateUpdated(newState):
                let queuedId = state.queue.indices.contains(state.index) ? state.queue[state.index].id : nil
                if let queuedId, let incomingId = newState.currentItem?.id, queuedId != incomingId {
                    return .none
                }
                let previousTime = state.currentTime
                let previousPlaying = state.isPlaying
                let previousItemId = state.currentItem?.id
                let previousDuration = state.duration
                let sameItem = newState.currentItem?.id == state.currentItem?.id
                let reachedEnd = newState.duration > 1 && newState.currentTime >= newState.duration - 1.5
                let shouldAdvance = newState.didFinish && !state.didFinish && !state.isResolving && sameItem && reachedEnd
                state.currentItem = newState.currentItem
                state.isPlaying = newState.isPlaying
                state.currentTime = newState.currentTime
                state.duration = newState.duration
                if newState.rate > 0 { state.rate = newState.rate }
                state.didFinish = newState.didFinish
                state.error = newState.error

                var effects: [Effect<Action>] = []
                if let seek = state.resumeSeek, newState.duration > seek, newState.currentTime < 1.5 {
                    state.resumeSeek = nil
                    effects.append(.run { _ in await playerClient.seek(seek) })
                }
                if shouldAdvance {
                    effects.append(nowPlayingUpdate(state))
                    effects.append(.send(.trackDidFinish))
                    return .merge(effects)
                }
                let clockMoved = abs(state.currentTime - previousTime) >= 1
                    || abs(state.duration - previousDuration) > 0.5
                let playbackChanged = previousPlaying != state.isPlaying || previousItemId != state.currentItem?.id
                if playbackChanged || clockMoved {
                    effects.append(nowPlayingUpdate(state))
                }
                return effects.isEmpty ? .none : .merge(effects)

            case .subscribeToPlayerState:
                return .merge(
                    .run { send in
                        PlayerRelay.shared.register { tracks, index, present, startPosition in
                            await send(.playQueue(tracks: tracks, startIndex: index, startPosition: startPosition))
                            if present {
                                await send(.openFullPlayer)
                            }
                        }
                        for await playerState in playerClient.playerStateStream() {
                            await send(.playerStateUpdated(playerState))
                        }
                    }.cancellable(id: PlayerClientCancellable(), cancelInFlight: true),
                    .run { send in
                        for await command in nowPlayingClient.commands() {
                            await send(.remoteCommand(command))
                        }
                    }.cancellable(id: RemoteCancellable(), cancelInFlight: true)
                )

            case let .remoteCommand(command):
                switch command {
                case .play: return .send(.playButtonTapped)
                case .pause: return .send(.pauseButtonTapped)
                case .next: return .send(.nextTrack)
                case .previous: return .send(.previousTrack)
                case let .seek(seconds): return .send(.seek(seconds))
                }

            case let .trackResolved(index, audio):
                guard state.queue.indices.contains(index) else { return .none }
                state.isResolving = false
                state.queue[index].audioURL = audio.audioURL
                state.queue[index].originalLyricURL = audio.originalLyricURL
                state.queue[index].explanationLyricURL = audio.explanationLyricURL
                let item = playerItem(state.queue[index])
                state.currentItem = item
                state.isPlaying = true
                return .merge(
                    .run { _ in await playerClient.play(item) },
                    loadLyrics(for: state.queue[index], kind: state.lyricKind),
                    .send(.refreshFavoriteStatus)
                )

            case let .playbackDenied(revertTo):
                state.isResolving = false
                if let revertTo { state.index = revertTo }
                state.alertMessage = "该内容为付费专栏，请订阅后收听。"
                return .none

            case let .playbackFailed(message):
                state.isResolving = false
                state.alertMessage = message
                return .none

            case let .lyricsLoaded(lines):
                state.lyricLines = lines
                return .none

            case let .setLyricKind(kind):
                state.lyricKind = kind
                guard state.queue.indices.contains(state.index) else { return .none }
                return loadLyrics(for: state.queue[state.index], kind: kind)

            case .openFullPlayer:
                state.showFullPlayer = true
                return .send(.refreshFavoriteStatus)

            case .closeFullPlayer:
                state.showFullPlayer = false
                return .none

            case .clearAlert:
                state.alertMessage = nil
                return .none

            case let .selectTrack(index):
                guard !state.isResolving, state.queue.indices.contains(index), index != state.index else { return .none }
                return advance(state: &state, to: index)

            case .downloadCurrent:
                guard state.queue.indices.contains(state.index) else { return .none }
                let track = state.queue[state.index]
                return .run { _ in
                    let url: URL
                    if let existing = track.audioURL {
                        url = existing
                    } else {
                        let resolved = try await trackResolver.resolve(track.sutraId, track.id)
                        url = resolved.audioURL
                    }
                    DownloadCenter.shared.download(itemId: track.id, title: track.title, remoteURL: url)
                }

            case .cyclePlayMode:
                let next = state.playMode.cycled()
                state.playMode = next
                PlayModeStore.current = next
                state.alertMessage = next.title
                return .none

            case .refreshFavoriteStatus:
                guard let itemId = state.currentItem?.id ?? state.queue[safe: state.index]?.id else { return .none }
                return .run { send in
                    let favorites = (try? await LibraryAPI.favorites()) ?? []
                    if let hit = favorites.first(where: { $0.sutraItemId == itemId || $0.id == itemId }) {
                        await send(.favoriteStatusLoaded(isFavorite: true, serverId: hit.serverId))
                    } else {
                        await send(.favoriteStatusLoaded(isFavorite: false, serverId: nil))
                    }
                }

            case let .favoriteStatusLoaded(isFavorite, serverId):
                state.isFavorite = isFavorite
                state.favoriteServerId = serverId
                return .none

            case .toggleFavorite:
                guard let itemId = state.currentItem?.id ?? state.queue[safe: state.index]?.id else { return .none }
                let wasFavorite = state.isFavorite
                let serverId = state.favoriteServerId
                return .run { send in
                    do {
                        if wasFavorite, let serverId, !serverId.isEmpty {
                            try await LibraryAPI.deleteFavorite(serverId: serverId)
                            await send(.favoriteToggled(isFavorite: false, serverId: nil))
                        } else {
                            try await LibraryAPI.addFavorite(itemId: itemId)
                            let favorites = (try? await LibraryAPI.favorites()) ?? []
                            let hit = favorites.first(where: { $0.sutraItemId == itemId || $0.id == itemId })
                            await send(.favoriteToggled(isFavorite: true, serverId: hit?.serverId))
                        }
                    } catch {
                        await send(.playbackFailed(wasFavorite ? "取消收藏失败" : "收藏失败"))
                    }
                }

            case let .favoriteToggled(isFavorite, serverId):
                state.isFavorite = isFavorite
                state.favoriteServerId = serverId
                state.alertMessage = isFavorite ? "已加入收藏" : "已取消收藏"
                return .none
            }
        }
    }

    private func move(state: inout State, auto: Bool, forward: Bool) -> Effect<Action> {
        guard !state.queue.isEmpty else { return .none }
        if auto, state.playMode == .single {
            state.didFinish = false
            state.currentTime = 0
            return .run { _ in
                await playerClient.seek(0)
                await playerClient.resume()
            }
        }
        guard let target = Self.targetIndex(
            from: state.index,
            count: state.queue.count,
            mode: state.playMode,
            forward: forward,
            auto: auto
        ) else {
            if auto {
                state.isPlaying = false
                return .none
            }
            state.alertMessage = forward ? "没有更多内容了" : "已经是第一首"
            return .none
        }
        if target == state.index, auto {
            state.didFinish = false
            state.currentTime = 0
            return .run { _ in
                await playerClient.seek(0)
                await playerClient.resume()
            }
        }
        return advance(state: &state, to: target)
    }

    private static func targetIndex(from index: Int, count: Int, mode: PlayMode, forward: Bool, auto: Bool) -> Int? {
        guard count > 0 else { return nil }
        switch mode {
        case .sequential:
            let next = forward ? index + 1 : index - 1
            return (0..<count).contains(next) ? next : nil
        case .shuffle:
            if count == 1 { return auto ? 0 : nil }
            var next = Int.random(in: 0..<count)
            var guardCount = 0
            while next == index, guardCount < 8 {
                next = Int.random(in: 0..<count)
                guardCount += 1
            }
            return next
        case .loop:
            if forward { return (index + 1) % count }
            return (index - 1 + count) % count
        case .single:
            if auto { return index }
            let next = forward ? index + 1 : index - 1
            return (0..<count).contains(next) ? next : nil
        }
    }

    private func advance(state: inout State, to index: Int) -> Effect<Action> {
        let previousId = state.queue[state.index].id
        let position = Int(state.currentTime)
        let revertTo = state.index
        state.index = index
        state.queue[index].audioURL = nil
        state.currentTime = 0
        state.duration = 0
        state.didFinish = false
        state.isPlaying = true
        state.lyricLines = []
        state.resumeSeek = nil
        state.isFavorite = false
        state.favoriteServerId = nil
        state.currentItem = playerItem(state.queue[index])
        return .merge(
            .run { _ in await trackResolver.reportHistory(previousId, position) },
            playCurrent(state: &state, revertTo: revertTo),
            .send(.refreshFavoriteStatus)
        )
    }

    private func playCurrent(state: inout State, revertTo: Int?) -> Effect<Action> {
        guard state.queue.indices.contains(state.index) else { return .none }
        let track = state.queue[state.index]
        let index = state.index
        if let local = trackResolver.localFile(track.id) {
            var localTrack = track
            localTrack.audioURL = local
            state.isResolving = false
            state.didFinish = false
            let item = playerItem(localTrack)
            state.currentItem = item
            state.isPlaying = true
            return .merge(
                .run { _ in await playerClient.play(item) },
                loadLyrics(for: track, kind: state.lyricKind)
            )
        }
        if track.audioURL != nil {
            state.isResolving = false
            state.didFinish = false
            let item = playerItem(track)
            state.currentItem = item
            state.isPlaying = true
            return .merge(
                .run { _ in await playerClient.play(item) },
                loadLyrics(for: track, kind: state.lyricKind)
            )
        }
        state.isResolving = true
        return .run { [sutraId = track.sutraId, itemId = track.id] send in
            do {
                let audio = try await trackResolver.resolve(sutraId, itemId)
                await send(.trackResolved(index: index, audio: audio))
            } catch let error as TrackResolveError {
                if error == .accessDenied {
                    await send(.playbackDenied(revertTo: revertTo))
                } else {
                    await send(.playbackFailed("获取音频失败"))
                }
            } catch let error as NetworkError where error == .accessDenied {
                await send(.playbackDenied(revertTo: revertTo))
            } catch {
                await send(.playbackFailed("获取音频失败"))
            }
        }
        .cancellable(id: TrackResolveCancellable(), cancelInFlight: true)
    }

    private func nowPlayingUpdate(_ state: State) -> Effect<Action> {
        let item = state.currentItem
        let time = state.currentTime
        let duration = state.duration
        let rate = state.rate
        let isPlaying = state.isPlaying
        let update = nowPlayingClient.update
        return .run { _ in
            await update(item, time, duration, rate, isPlaying)
        }
    }

    private func loadLyrics(for track: QueueTrack, kind: LyricKind) -> Effect<Action> {
        let urls = kind == .original
            ? [track.originalLyricURL, track.explanationLyricURL]
            : [track.explanationLyricURL, track.originalLyricURL]
        return .run { send in
            var lines: [LyricLine] = []
            for url in urls.compactMap({ $0 }) {
                lines = await Self.fetchLyrics(url)
                if !lines.isEmpty { break }
            }
            await send(.lyricsLoaded(lines))
        }
    }

    private static func fetchLyrics(_ url: URL) async -> [LyricLine] {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              !data.isEmpty else { return [] }
        return LyricParser.lines(from: decodeLyric(data))
    }

    private static func decodeLyric(_ data: Data) -> String {
        if let text = String(data: data, encoding: .utf8), !text.contains("\u{FFFD}") {
            return text
        }
        let gbk = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        return String(data: data, encoding: gbk) ?? String(decoding: data, as: UTF8.self)
    }

    private func playerItem(_ track: QueueTrack) -> PlayerItem {
        PlayerItem(
            id: track.id,
            url: track.audioURL ?? URL(string: "about:blank")!,
            title: track.title,
            artist: track.artist,
            imageUrl: track.imageUrl,
            sutraId: track.sutraId,
            originalLyricURL: track.originalLyricURL,
            explanationLyricURL: track.explanationLyricURL
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct PlayerClientCancellable: Hashable {}
private struct RemoteCancellable: Hashable {}
private struct TrackResolveCancellable: Hashable {}

public final class PlayerRelay: @unchecked Sendable {
    public static let shared = PlayerRelay()
    private let lock = NSLock()
    private var handler: (@Sendable ([QueueTrack], Int, Bool, Double) async -> Void)?

    public func register(_ handler: @escaping @Sendable ([QueueTrack], Int, Bool, Double) async -> Void) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    public func play(tracks: [QueueTrack], startIndex: Int, presentPlayer: Bool = false, startPosition: Double = 0) {
        lock.lock()
        let handler = handler
        lock.unlock()
        guard let handler else { return }
        Task { await handler(tracks, startIndex, presentPlayer, startPosition) }
    }
}

public struct PlayerStoreEnvironmentKey: EnvironmentKey {
    public static let defaultValue: StoreOf<PlayerFeature> = Store(
        initialState: PlayerFeature.State()
    ) {
        PlayerFeature()
    }
}

extension EnvironmentValues {
    public var playerStore: StoreOf<PlayerFeature> {
        get { self[PlayerStoreEnvironmentKey.self] }
        set { self[PlayerStoreEnvironmentKey.self] = newValue }
    }
}
