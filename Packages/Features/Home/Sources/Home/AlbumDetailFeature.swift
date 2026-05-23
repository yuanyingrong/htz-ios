import Foundation
import ComposableArchitecture
import NetworkKit

@Reducer
public struct AlbumDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public let album: Album
        public var items: [SutraItem] = []
        public var isLoading: Bool = false
        public var errorMessage: String?
        
        public init(album: Album) {
            self.album = album
        }
    }
    
    public enum Action {
        case onAppear
        case itemsResponse(Result<[SutraItem], NetworkError>)
    }
    
    @Dependency(\.homeClient) var homeClient
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [sutraId = state.album.id] send in
                    do {
                        let items = try await homeClient.getSutraItems(sutraId)
                        await send(.itemsResponse(.success(items)))
                    } catch {
                        await send(.itemsResponse(.failure(error as? NetworkError ?? .unknown)))
                    }
                }
                
            case let .itemsResponse(.success(items)):
                state.items = items
                state.isLoading = false
                return .none
                
            case let .itemsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to load album items"
                return .none
            }
        }
    }
}
