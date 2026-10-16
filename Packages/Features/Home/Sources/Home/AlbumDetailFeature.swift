import Foundation
import ComposableArchitecture
import NetworkKit
import HTZAudio
import PlayerFeature

public struct PendingQueue: Equatable {
    public var tracks: [QueueTrack]
    public var index: Int
    public var token: Int
}

@Reducer
public struct AlbumDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var album: Album
        public var items: [SutraItem] = []
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var alertMessage: String?
        public var isResolvingAudio: Bool = false
        public var pendingQueue: PendingQueue?
        public var playToken: Int = 0
        public var resumeItemId: String?
        public var resumeTitle: String?
        public var resumePosition: Int = 0
        
        public init(album: Album) {
            self.album = album
        }
    }
    
    public enum Action {
        case onAppear
        case itemsResponse(Result<[SutraItem], NetworkError>)
        case coverResolved(String)
        case trackTapped(SutraItem)
        case toggleSort
        case resumeLoaded(id: String?, title: String?, position: Int)
        case favoriteTapped(SutraItem)
        case downloadTapped(SutraItem)
        case downloadAlbum
        case audioURLResolved(item: SutraItem, signedAudioURL: URL, originalLyric: URL?, explanationLyric: URL?)
        case downloadReady(item: SutraItem, url: URL)
        case playbackPermissionDenied
        case playbackFailed(String)
        case clearAlert
        case clearPendingQueue
        case libraryMessage(String)
    }
    
    @Dependency(\.homeClient) var homeClient
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .merge(
                    .run { [sutraId = state.album.id] send in
                        do {
                            let items = try await homeClient.getSutraItems(sutraId)
                            await send(.itemsResponse(.success(items)))
                        } catch {
                            await send(.itemsResponse(.failure(error as? NetworkError ?? .unknown)))
                        }
                    },
                    .run { [sutraId = state.album.id] send in
                        if let signedCover = try? await homeClient.getSutraCoverURL(sutraId) {
                            await send(.coverResolved(signedCover))
                        }
                    }
                )
                
            case let .coverResolved(url):
                state.album = state.album.replacingImageUrl(url)
                return .none
                
            case let .itemsResponse(.success(items)):
                state.items = items
                state.isLoading = false
                let ids = Set(items.map(\.id))
                return .run { send in
                    let histories = (try? await LibraryAPI.histories()) ?? []
                    if let hit = histories.first(where: { ids.contains($0.sutraItemId) }) {
                        await send(.resumeLoaded(id: hit.sutraItemId, title: hit.title, position: hit.lastPosition))
                    }
                }

            case .itemsResponse(.failure):
                state.isLoading = false
                state.errorMessage = "章节加载失败"
                return .none

            case .toggleSort:
                state.items.reverse()
                return .none

            case let .resumeLoaded(id, title, position):
                state.resumeItemId = id
                state.resumeTitle = title
                state.resumePosition = position
                return .none
                
            case let .trackTapped(item):
                state.isResolvingAudio = true
                return resolve(item: item, sutraId: state.album.id, purpose: .play)

            case let .favoriteTapped(item):
                return .run { send in
                    do {
                        try await LibraryAPI.addFavorite(itemId: item.id)
                        await send(.libraryMessage("已加入收藏"))
                    } catch {
                        await send(.libraryMessage("收藏失败"))
                    }
                }

            case let .downloadTapped(item):
                state.isResolvingAudio = true
                return resolve(item: item, sutraId: state.album.id, purpose: .download)

            case .downloadAlbum:
                let album = state.album
                let items = state.items
                return .run { _ in
                    for item in items {
                        if DownloadCenter.shared.localFile(for: item.id) != nil { continue }
                        guard let file = try? await LibraryAPI.fileURL(sutraId: album.id, itemId: item.id),
                              let url = file.audioURL else { continue }
                        DownloadCenter.shared.download(itemId: item.id, title: item.title ?? album.name, remoteURL: url)
                    }
                }
                
            case let .audioURLResolved(item, audioURL, originalLyric, explanationLyric):
                state.isResolvingAudio = false
                let tracks = state.items.map { row in
                    QueueTrack(
                        id: row.id,
                        sutraId: state.album.id,
                        title: row.title ?? "未命名",
                        artist: state.album.name,
                        imageUrl: state.album.imageUrl.flatMap(URL.init),
                        audioURL: row.id == item.id ? audioURL : nil,
                        originalLyricURL: row.id == item.id ? originalLyric : nil,
                        explanationLyricURL: row.id == item.id ? explanationLyric : nil
                    )
                }
                let index = state.items.firstIndex(where: { $0.id == item.id }) ?? 0
                state.playToken += 1
                state.pendingQueue = PendingQueue(tracks: tracks, index: index, token: state.playToken)
                let queued = tracks
                let start = index
                return .run { _ in PlayerRelay.shared.play(tracks: queued, startIndex: start, presentPlayer: true) }

            case let .downloadReady(item, url):
                state.isResolvingAudio = false
                DownloadCenter.shared.download(itemId: item.id, title: item.title ?? state.album.name, remoteURL: url)
                state.alertMessage = "已开始下载"
                return .none
                
            case .playbackPermissionDenied:
                state.isResolvingAudio = false
                state.alertMessage = "该内容为付费专栏，请订阅后收听。"
                return .none
                
            case let .playbackFailed(message):
                state.isResolvingAudio = false
                state.alertMessage = message
                return .none
                
            case .clearAlert:
                state.alertMessage = nil
                return .none
                
            case .clearPendingQueue:
                state.pendingQueue = nil
                return .none

            case let .libraryMessage(message):
                state.alertMessage = message.isEmpty ? nil : message
                return .none
            }
        }
    }

    private enum ResolvePurpose { case play, download }

    private func resolve(item: SutraItem, sutraId: String, purpose: ResolvePurpose) -> Effect<Action> {
        .run { send in
            do {
                let file = try await homeClient.getSutraItemFileURL(sutraId, item.id)
                guard let audioString = file.signedUrls?.audio, let audioURL = URL(string: audioString) else {
                    await send(.playbackPermissionDenied)
                    return
                }
                switch purpose {
                case .play:
                    await send(.audioURLResolved(
                        item: item,
                        signedAudioURL: audioURL,
                        originalLyric: file.signedUrls?.originalLyric.flatMap(URL.init(string:)),
                        explanationLyric: file.signedUrls?.explanationLyric.flatMap(URL.init(string:))
                    ))
                case .download:
                    await send(.downloadReady(item: item, url: audioURL))
                }
            } catch let error as NetworkError where error == .accessDenied {
                await send(.playbackPermissionDenied)
            } catch {
                await send(.playbackFailed("获取音频失败"))
            }
        }
    }
}
