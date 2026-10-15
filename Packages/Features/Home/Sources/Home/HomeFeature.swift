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
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var path = StackState<Path.State>()
        
        public init() {}
    }
    
    public enum Action {
        case onAppear
        case bannersResponse(Result<[Banner], NetworkError>)
        case albumsResponse(Result<[Album], NetworkError>)
        case albumTapped(Album)
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
                state.errorMessage = "Failed to load albums"
                return .none
                
            case let .albumTapped(album):
                state.path.append(.albumDetail(AlbumDetailFeature.State(album: album)))
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
