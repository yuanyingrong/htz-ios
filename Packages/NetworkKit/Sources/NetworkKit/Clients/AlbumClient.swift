import Foundation
import Combine
import Moya

public protocol AlbumClientProtocol {
    func getAlbums() -> AnyPublisher<[Album], NetworkError>
}

public class AlbumClient: AlbumClientProtocol {
    private let networkManager: NetworkManager<HTZAPI>
    
    public init(networkManager: NetworkManager<HTZAPI> = NetworkManager<HTZAPI>()) {
        self.networkManager = networkManager
    }
    
    public func getAlbums() -> AnyPublisher<[Album], NetworkError> {
        return networkManager.request(.albums)
    }
}
