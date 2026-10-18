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
        public var toast: String?
        public var showFullPlayer: Bool = false
        public var lyricKind: LyricKind = .explanation
        public var lyricLines: [LyricLine] = []
        public var playMode: PlayMode = PlayModeStore.current
        public var isFavorite: Bool = false
        public var favoriteServerId: String?
        public var resumeSeek: Double?
        public var sleepTimer: SleepTimer?
        public var sleepSecondsLeft: Int?
        @Shared(.lyricFontSize) public var lyricFontSize: Double = 17
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

        public mutating func showToast(_ message: String?) {
            toast = message
        }
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
        case playbackFailed(String, revertTo: Int?)
        case lyricsLoaded([LyricLine])
        case setLyricKind(LyricKind)
        case openFullPlayer
        case closeFullPlayer
        case showFullPlayer(Bool)
        case toastChanged(String?)
        case downloadCurrent
        case downloadQueued
        case selectTrack(Int)
        case cyclePlayMode
        case refreshFavoriteStatus
        case favoriteStatusLoaded(isFavorite: Bool, serverId: String?)
        case toggleFavorite
        case favoriteToggled(isFavorite: Bool, serverId: String?)
        case setSleepTimer(SleepTimer?)
        case sleepTick
        case setLyricFontSize(Double)
        case reverseQueue
    }

    public static let rates: [Double] = [0.5, 0.75, 1.0, 1.2, 1.5, 2.0]

    @Dependency(\.playerClient) var playerClient
    @Dependency(\.trackResolver) var trackResolver
    @Dependency(\.nowPlayingClient) var nowPlayingClient
    @Dependency(\.library) var library
    @Dependency(\.downloads) var downloads
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .playQueue(tracks, startIndex, startPosition):
                state.queue = tracks
                state.index = min(max(0, startIndex), max(tracks.count - 1, 0))
                state.showToast(nil)
                state.lyricLines = []
                state.resumeSeek = startPosition > 1 ? startPosition : nil
                state.isFavorite = false
                state.favoriteServerId = nil
                guard state.queue.indices.contains(state.index) else { return .none }
                let itemId = state.queue[state.index].id
                return .merge(
                    playCurrent(state: &state, revertTo: nil),
                    .run { _ in await trackResolver.markPlayed(itemId) },
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
                if case let .episodes(count) = state.sleepTimer {
                    if count <= 1 {
                        state.sleepTimer = nil
                        state.isPlaying = false
                        return .run { _ in await playerClient.pause() }
                    }
                    state.sleepTimer = .episodes(count - 1)
                }
                return move(state: &state, auto: true, forward: true)

            case let .seek(seconds):
                return .run { _ in await playerClient.seek(seconds) }

            case let .setRate(rate):
                state.rate = rate
                return .run { _ in await playerClient.setRate(rate) }

            case let .playerStateUpdated(newState):
                let queuedId = state.queue.indices.contains(state.index) ? state.queue[state.index].id : nil
                // Ignore engine ticks for the previous item while we are switching tracks.
                if let queuedId, let incomingId = newState.currentItem?.id, queuedId != incomingId {
                    return .none
                }
                if state.isResolving, newState.currentItem?.id != queuedId {
                    return .none
                }
                // Never clobber UI with an empty engine item during an active queue.
                if newState.currentItem == nil, state.currentItem != nil {
                    return .none
                }
                let previousTime = state.currentTime
                let previousPlaying = state.isPlaying
                let previousItemId = state.currentItem?.id
                let previousDuration = state.duration
                let sameItem = newState.currentItem?.id == state.currentItem?.id
                let reachedEnd = newState.duration > 1 && newState.currentTime >= newState.duration - 1.5
                let shouldAdvance = newState.didFinish && !state.didFinish && !state.isResolving && sameItem && reachedEnd
                if let item = newState.currentItem {
                    state.currentItem = item
                }
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
                state.queue[index].originalLyricURL = audio.originalLyricURL ?? state.queue[index].originalLyricURL
                state.queue[index].explanationLyricURL = audio.explanationLyricURL ?? state.queue[index].explanationLyricURL
                let item = playerItem(state.queue[index])
                state.currentItem = item
                state.isPlaying = true
                return .merge(
                    .run { _ in await playerClient.play(item) },
                    loadLyrics(for: state.queue[index], kind: state.lyricKind),
                    .send(.refreshFavoriteStatus)
                )

            case let .playbackDenied(revertTo):
                return restoreAfterFailedAdvance(
                    state: &state,
                    revertTo: revertTo,
                    message: "该内容为付费专栏，请订阅后收听。"
                )

            case let .playbackFailed(message, revertTo):
                return restoreAfterFailedAdvance(
                    state: &state,
                    revertTo: revertTo,
                    message: message
                )

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

            case let .showFullPlayer(show):
                state.showFullPlayer = show
                return show ? .send(.refreshFavoriteStatus) : .none

            case let .toastChanged(message):
                state.toast = message
                return .none

            case let .selectTrack(index):
                guard !state.isResolving, state.queue.indices.contains(index), index != state.index else { return .none }
                return advance(state: &state, to: index)

            case .downloadCurrent:
                guard state.queue.indices.contains(state.index) else { return .none }
                let track = state.queue[state.index]
                if downloads.isDownloaded(track.id) {
                    state.showToast("已下载")
                    return .none
                }
                return .run { send in
                    do {
                        let url: URL
                        if let existing = track.audioURL, !existing.isFileURL {
                            url = existing
                        } else {
                            url = try await trackResolver.resolve(track.sutraId, track.id).audioURL
                        }
                        downloads.download(DownloadRequest(
                            itemId: track.id,
                            title: track.title,
                            sutraId: track.sutraId,
                            albumName: track.artist ?? "",
                            imageURL: track.imageUrl?.absoluteString,
                            lesson: 0,
                            remoteURL: url
                        ))
                        await send(.downloadQueued)
                    } catch {
                        await send(.playbackFailed("下载失败", revertTo: nil))
                    }
                }

            case .downloadQueued:
                state.showToast("已加入下载列表")
                return .none

            case .cyclePlayMode:
                let next = state.playMode.cycled()
                state.playMode = next
                PlayModeStore.current = next
                state.showToast(next.title)
                return .none

            case .refreshFavoriteStatus:
                guard let itemId = state.currentItem?.id ?? state.queue[safe: state.index]?.id else { return .none }
                return .run { send in
                    let favorites = (try? await library.favorites()) ?? []
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
                            try await library.deleteFavorite(serverId)
                            await send(.favoriteToggled(isFavorite: false, serverId: nil))
                        } else {
                            try await library.addFavorite(itemId)
                            let favorites = (try? await library.favorites()) ?? []
                            let hit = favorites.first(where: { $0.sutraItemId == itemId || $0.id == itemId })
                            await send(.favoriteToggled(isFavorite: true, serverId: hit?.serverId))
                        }
                    } catch {
                        await send(.playbackFailed(wasFavorite ? "取消收藏失败" : "收藏失败", revertTo: nil))
                    }
                }

            case let .favoriteToggled(isFavorite, serverId):
                state.isFavorite = isFavorite
                state.favoriteServerId = serverId
                state.showToast(isFavorite ? "已加入收藏" : "已取消收藏")
                return .none

            case let .setSleepTimer(timer):
                state.sleepTimer = timer
                guard case let .minutes(minutes) = timer else {
                    state.sleepSecondsLeft = nil
                    return .cancel(id: SleepTimerCancellable())
                }
                state.sleepSecondsLeft = minutes * 60
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.sleepTick)
                    }
                }
                .cancellable(id: SleepTimerCancellable(), cancelInFlight: true)

            case .sleepTick:
                guard let left = state.sleepSecondsLeft else { return .cancel(id: SleepTimerCancellable()) }
                if left > 1 {
                    state.sleepSecondsLeft = left - 1
                    return .none
                }
                state.sleepSecondsLeft = nil
                state.sleepTimer = nil
                return .merge(
                    .cancel(id: SleepTimerCancellable()),
                    .send(.pauseButtonTapped)
                )

            case let .setLyricFontSize(size):
                state.$lyricFontSize.withLock { $0 = size }
                return .none

            case .reverseQueue:
                guard state.queue.count > 1 else { return .none }
                state.queue.reverse()
                state.index = state.queue.count - 1 - state.index
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
        // Manual next/prev always follow list order (下一集/上一集).
        // Shuffle only affects auto-advance when a track finishes — otherwise
        // tapping next feels like a random jump to a far episode.
        let modeForMove = auto ? state.playMode : (state.playMode == .shuffle ? .sequential : state.playMode)
        guard let target = Self.targetIndex(
            from: state.index,
            count: state.queue.count,
            mode: modeForMove,
            forward: forward,
            auto: auto
        ) else {
            if auto {
                state.isPlaying = false
                return .none
            }
            state.showToast(forward ? "没有更多内容了" : "已经是第一首")
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

    private func restoreAfterFailedAdvance(
        state: inout State,
        revertTo: Int?,
        message: String
    ) -> Effect<Action> {
        state.isResolving = false
        state.showToast(message)
        guard let revertTo, state.queue.indices.contains(revertTo) else { return .none }
        state.index = revertTo
        state.currentTime = 0
        state.duration = 0
        state.didFinish = false
        state.lyricLines = []
        state.resumeSeek = nil
        state.currentItem = playerItem(state.queue[revertTo])
        // Resume the previous track; it usually still has a usable URL cached.
        return playCurrent(state: &state, revertTo: nil)
    }

    private func advance(state: inout State, to index: Int) -> Effect<Action> {
        let previousId = state.queue[state.index].id
        let position = Int(state.currentTime)
        let revertTo = state.index
        state.index = index
        // Keep a cached signed URL when we already have one; clearing forced a
        // re-resolve on every skip and made next/prev feel dead while waiting.
        state.currentTime = 0
        state.duration = 0
        state.didFinish = false
        state.isPlaying = true
        state.lyricLines = []
        state.resumeSeek = nil
        state.isFavorite = false
        state.favoriteServerId = nil
        state.currentItem = playerItem(state.queue[index])
        let nextId = state.queue[index].id
        return .merge(
            .run { _ in await trackResolver.reportHistory(previousId, position) },
            .run { _ in await trackResolver.markPlayed(nextId) },
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
            state.queue[index].audioURL = local
            state.isResolving = false
            state.didFinish = false
            let item = playerItem(localTrack)
            state.currentItem = item
            state.isPlaying = true
            return .merge(
                .run { _ in await playerClient.play(item) },
                loadLyrics(for: localTrack, kind: state.lyricKind)
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
            // Pausing in a sibling effect could land after play() and silence the new track.
            await playerClient.pause()
            do {
                let audio = try await trackResolver.resolve(sutraId, itemId)
                await send(.trackResolved(index: index, audio: audio))
            } catch is CancellationError {
                // Superseded by another resolve; the replacement path owns isResolving.
            } catch let error as TrackResolveError {
                if error == .accessDenied {
                    await send(.playbackDenied(revertTo: revertTo))
                } else {
                    await send(.playbackFailed("获取音频失败", revertTo: revertTo))
                }
            } catch let error as NetworkError where error == .accessDenied {
                await send(.playbackDenied(revertTo: revertTo))
            } catch {
                await send(.playbackFailed("获取音频失败", revertTo: revertTo))
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
private struct SleepTimerCancellable: Hashable {}

public enum SleepTimer: Equatable, Sendable {
    case minutes(Int)
    case episodes(Int)

    public var title: String {
        switch self {
        case let .minutes(minutes): return "\(minutes) 分钟"
        case .episodes(1): return "播完本集"
        case let .episodes(count): return "播完 \(count) 集"
        }
    }
}

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
