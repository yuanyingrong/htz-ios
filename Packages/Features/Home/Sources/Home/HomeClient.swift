import Foundation
import ComposableArchitecture
import NetworkKit
import Combine

public struct HomeClient {
    public var getBanners: @Sendable () async throws -> [Banner]
    public var getAlbums: @Sendable () async throws -> [Album]
}

extension HomeClient: DependencyKey {
    public static let liveValue = Self(
        getBanners: {
            let manager = NetworkManager<HTZAPI>()
            return try await manager.request(.recommendations)
                .map { (banners: [Banner]) in banners }
                .eraseToAnyPublisher()
                .async()
        },
        getAlbums: {
            let manager = NetworkManager<HTZAPI>()
            return try await manager.request(.albums)
                .map { (albums: [Album]) in albums }
                .eraseToAnyPublisher()
                .async()
        }
    )
}

extension DependencyValues {
    public var homeClient: HomeClient {
        get { self[HomeClient.self] }
        set { self[HomeClient.self] = newValue }
    }
}

// Helper to bridge AnyPublisher to async/await
extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                }
            )
        }
    }
}
