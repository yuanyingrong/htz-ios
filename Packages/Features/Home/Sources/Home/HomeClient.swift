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
            // The legacy app mocks banners by taking from the albums request.
            // We fetch the albums and take the first few to act as banners.
            let response: APIResponse<[Album]> = try await manager.request(.albums)
                .eraseToAnyPublisher()
                .async()
            let albums = response.data ?? []
            let ossBaseUrl = "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/"
            
            // Map the first 3 albums to Banners for the carousel
            return albums.prefix(3).map { album in
                let imageUrl = album.imageUrl.map { "\(ossBaseUrl)\($0)" }
                return Banner(id: album.id, name: album.name, description: "", imageUrl: imageUrl, sort: "0")
            }
        },
        getAlbums: {
            let manager = NetworkManager<HTZAPI>()
            let response: APIResponse<[Album]> = try await manager.request(.albums)
                .eraseToAnyPublisher()
                .async()
            let albums = response.data ?? []
            let ossBaseUrl = "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/"
            
            return albums.map { album in
                var formattedAlbum = album
                // We need to recreate the struct to modify it or use a mapping logic
                return Album(
                    id: album.id,
                    name: album.name,
                    imageUrl: album.imageUrl.map { "\(ossBaseUrl)\($0)" }
                )
            }
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
