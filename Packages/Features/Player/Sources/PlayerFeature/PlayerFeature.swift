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
        public var lyricKind: LyricKind = .original
        public var lyricLines: [LyricLine] = []
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
        case playQueue(tracks: [QueueTrack], startIndex: Int)
        case playButtonTapped
        case pauseButtonTapped
        case nextTrack
        case previousTrack
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
    }

    @Dependency(\.playerClient) var playerClient
    @Dependency(\.trackResolver) var trackResolver
    @Dependency(\.nowPlayingClient) var nowPlayingClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .playQueue(tracks, startIndex):
                state.queue = tracks
                state.index = min(max(0, startIndex), max(tracks.count - 1, 0))
                state.alertMessage = nil
                state.lyricLines = []
                return playCurrent(state: &state, revertTo: nil)

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
                guard !state.isResolving, state.index + 1 < state.queue.count else { return .none }
                return advance(state: &state, to: state.index + 1)

            case .previousTrack:
                guard !state.isResolving, state.index > 0 else { return .none }
                return advance(state: &state, to: state.index - 1)

            case let .seek(seconds):
                return .run { _ in await playerClient.seek(seconds) }

            case let .setRate(rate):
                state.rate = rate
                return .run { _ in await playerClient.setRate(rate) }

            case let .playerStateUpdated(newState):
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
                let item = newState.currentItem
                let time = newState.currentTime
                let duration = newState.duration
                let rate = state.rate
                let isPlaying = newState.isPlaying
                let update = nowPlayingClient.update
                let nowPlaying = Effect<Action>.run { _ in
                    await update(item, time, duration, rate, isPlaying)
                }
                if shouldAdvance {
                    return .merge(nowPlaying, .send(.nextTrack))
                }
                return nowPlaying

            case .subscribeToPlayerState:
                return .merge(
                    .run { send in
                        PlayerRelay.shared.register { tracks, index, present in
                            await send(.playQueue(tracks: tracks, startIndex: index))
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
                return .merge(
                    .run { _ in await playerClient.play(item) },
                    loadLyrics(for: state.queue[index], kind: state.lyricKind)
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
                return .none

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
            }
        }
    }

    private func advance(state: inout State, to index: Int) -> Effect<Action> {
        let previousId = state.queue[state.index].id
        let position = Int(state.currentTime)
        let revertTo = state.index
        state.index = index
        state.queue[index].audioURL = nil
        return .merge(
            .run { _ in await trackResolver.reportHistory(previousId, position) },
            playCurrent(state: &state, revertTo: revertTo)
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
    }

    private func loadLyrics(for track: QueueTrack, kind: LyricKind) -> Effect<Action> {
        let url = kind == .original ? track.originalLyricURL : track.explanationLyricURL
        guard let url else {
            return .send(.lyricsLoaded([]))
        }
        return .run { send in
            let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            await send(.lyricsLoaded(LyricParser.parse(text)))
        }
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

private struct PlayerClientCancellable: Hashable {}
private struct RemoteCancellable: Hashable {}

public final class PlayerRelay: @unchecked Sendable {
    public static let shared = PlayerRelay()
    private let lock = NSLock()
    private var handler: (@Sendable ([QueueTrack], Int, Bool) async -> Void)?

    public func register(_ handler: @escaping @Sendable ([QueueTrack], Int, Bool) async -> Void) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    public func play(tracks: [QueueTrack], startIndex: Int, presentPlayer: Bool = false) {
        lock.lock()
        let handler = handler
        lock.unlock()
        guard let handler else { return }
        Task { await handler(tracks, startIndex, presentPlayer) }
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
