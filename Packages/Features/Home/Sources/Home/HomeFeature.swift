import Foundation
import ComposableArchitecture
import NetworkKit
import PlayerFeature

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var banners: [Banner] = []
        public var albums: [Album] = []
        public var recentHistories: [ListenHistoryItem] = []
        public var historyCovers: [String: String] = [:]
        public var checkIn = HomeStats.checkIn(dates: [])
        public var study = HomeStats.study(durations: [:], completed: 0)
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var notice: String?
        public var path = StackState<Path.State>()
        
        public init() {}
    }
    
    public enum Action {
        case onAppear
        case loadDashboard
        case bannersResponse(Result<[Banner], NetworkError>)
        case albumsResponse(Result<[Album], NetworkError>)
        case historiesLoaded([ListenHistoryItem], covers: [String: String])
        case statsLoaded(HomeStats.CheckIn, HomeStats.Study)
        case albumTapped(Album)
        case playHistory(ListenHistoryItem)
        case notice(String)
        case clearNotice
        case path(StackAction<Path.State, Path.Action>)
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
                    .run { send in
                        do {
                            let banners = try await homeClient.getBanners()
                            await send(.bannersResponse(.success(banners)))
                        } catch {
                            await send(.bannersResponse(.failure(error as? NetworkError ?? .unknown)))
                        }
                    },
                    .run { send in
                        do {
                            let albums = try await homeClient.getAlbums()
                            await send(.albumsResponse(.success(albums)))
                        } catch {
                            await send(.albumsResponse(.failure(error as? NetworkError ?? .unknown)))
                        }
                    }
                )
                
            case let .bannersResponse(.success(banners)):
                state.banners = banners
                return .none
                
            case let .bannersResponse(.failure(error)):
                return .none
                
            case let .albumsResponse(.success(albums)):
                state.albums = albums
                state.isLoading = false
                return .none
                
            case let .albumsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = "专辑加载失败"
                return .none

            case .loadDashboard:
                return .merge(
                    .run { send in
                        let histories = (try? await LibraryAPI.histories()) ?? []
                        let recent = Array(histories.prefix(3))
                        var covers: [String: String] = [:]
                        for item in recent where covers[item.sutraId] == nil && !item.sutraId.isEmpty {
                            if item.cover.hasPrefix("http") {
                                covers[item.sutraId] = item.cover
                            } else if let signed = try? await homeClient.getSutraCoverURL(item.sutraId) {
                                covers[item.sutraId] = signed
                            }
                        }
                        await send(.historiesLoaded(recent, covers: covers))
                    },
                    .run { send in
                        let unionid = AuthManager.shared.unionid ?? ""
                        let stats = await HomeStats.load(unionid: unionid)
                        await send(.statsLoaded(stats.0, stats.1))
                    }
                )

            case let .historiesLoaded(items, covers):
                state.recentHistories = items
                state.historyCovers = covers
                return .none

            case let .statsLoaded(checkIn, study):
                state.checkIn = checkIn
                state.study = study
                return .none

            case let .albumTapped(album):
                state.path.append(.albumDetail(AlbumDetailFeature.State(album: album)))
                return .none

            case let .playHistory(item):
                return .run { send in
                    do {
                        let file = try await LibraryAPI.fileURL(sutraId: item.sutraId, itemId: item.sutraItemId)
                        guard let url = file.audioURL else {
                            await send(.notice("获取音频失败"))
                            return
                        }
                        let cover = try? await homeClient.getSutraCoverURL(item.sutraId)
                        PlayerRelay.shared.play(
                            tracks: [
                                QueueTrack(
                                    id: item.sutraItemId,
                                    sutraId: item.sutraId,
                                    title: item.title,
                                    artist: item.sutraName,
                                    imageUrl: cover.flatMap(URL.init),
                                    audioURL: url,
                                    originalLyricURL: file.originalLyricURL,
                                    explanationLyricURL: file.explanationLyricURL
                                )
                            ],
                            startIndex: 0,
                            presentPlayer: true,
                            startPosition: Double(item.lastPosition >= 100_000 ? item.lastPosition / 1000 : item.lastPosition)
                        )
                    } catch let error as NetworkError where error == .accessDenied {
                        await send(.notice("该内容为付费专栏，请订阅后收听。"))
                    } catch {
                        await send(.notice("获取音频失败"))
                    }
                }

            case let .notice(message):
                state.notice = message
                return .none

            case .clearNotice:
                state.notice = nil
                return .none
                
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
    
    @Reducer(state: .equatable)
    public enum Path {
        case albumDetail(AlbumDetailFeature)
    }
}
