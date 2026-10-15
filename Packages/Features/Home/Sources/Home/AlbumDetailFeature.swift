import Foundation
import ComposableArchitecture
import NetworkKit
import HTZAudio
import PlayerFeature

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
        public var pendingPlayItem: PlayerItem?
        
        public init(album: Album) {
            self.album = album
        }
    }
    
    public enum Action {
        case onAppear
        case itemsResponse(Result<[SutraItem], NetworkError>)
        case coverResolved(String)
        case trackTapped(SutraItem)
        case audioURLResolved(item: SutraItem, signedAudioURL: URL)
        case playbackPermissionDenied
        case playbackFailed(String)
        case clearAlert
        case clearPendingPlayItem
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
                state.album = Album(id: state.album.id, name: state.album.name, imageUrl: url)
                return .none
                
            case let .itemsResponse(.success(items)):
                state.items = items
                state.isLoading = false
                return .none
                
            case let .itemsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to load album items"
                return .none
                
            case let .trackTapped(item):
                state.isResolvingAudio = true
                return .run { [sutraId = state.album.id] send in
                    print("[HTZDebug] Track tapped: id=\(item.id), title=\(item.title ?? ""), isTrial=\(String(describing: item.isTrial))")
                    do {
                        let fileResp = try await homeClient.getSutraItemFileURL(sutraId, item.id)
                        print("[HTZDebug] File URL response: isPaid=\(String(describing: fileResp.isPaid)), isTrial=\(String(describing: fileResp.isTrial)), signedAudio=\(fileResp.signedUrls?.audio ?? "nil")")
                        if let audioStr = fileResp.signedUrls?.audio, let audioURL = URL(string: audioStr) {
                            await send(.audioURLResolved(item: item, signedAudioURL: audioURL))
                        } else {
                            await send(.playbackPermissionDenied)
                        }
                    } catch let error as NetworkError {
                        print("[HTZDebug] File URL error (NetworkError): \(error)")
                        if error == .accessDenied {
                            await send(.playbackPermissionDenied)
                        } else {
                            await send(.playbackFailed("获取音频失败: \(error)"))
                        }
                    } catch {
                        print("[HTZDebug] File URL error (general): \(error)")
                        await send(.playbackFailed("获取音频失败: \(error.localizedDescription)"))
                    }
                }
                
            case let .audioURLResolved(item, audioURL):
                state.isResolvingAudio = false
                let playerItem = PlayerItem(
                    id: item.id,
                    url: audioURL,
                    title: item.title ?? "Unknown Title",
                    artist: state.album.name,
                    imageUrl: state.album.imageUrl.flatMap(URL.init)
                )
                state.pendingPlayItem = playerItem
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
                
            case .clearPendingPlayItem:
                state.pendingPlayItem = nil
                return .none
            }
        }
    }
}
