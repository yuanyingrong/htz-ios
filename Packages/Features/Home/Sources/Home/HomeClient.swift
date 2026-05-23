import Foundation
import ComposableArchitecture
import NetworkKit
import Combine

public struct HomeClient {
    public var getBanners: @Sendable () async throws -> [Banner]
    public var getAlbums: @Sendable () async throws -> [Album]
    public var getSutraItems: @Sendable (String) async throws -> [SutraItem]
}

extension HomeClient: DependencyKey {
    private static let ossBaseUrl = "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/"
    
    public static let liveValue = Self(
        getBanners: {
            let manager = NetworkManager<HTZAPI>()
            let response: APIResponse<[Album]> = try await manager.request(.albums)
                .eraseToAnyPublisher()
                .async()
            let albums = response.data ?? []
            
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
            
            return albums.map { album in
                Album(
                    id: album.id,
                    name: album.name,
                    imageUrl: album.imageUrl.map { "\(ossBaseUrl)\($0)" }
                )
            }
        },
        getSutraItems: { sutraId in
            let manager = NetworkManager<HTZAPI>()
            let response: APIResponse<[SutraItem]> = try await manager.request(.items(sutraId: sutraId, pageIndex: 0, pageSize: 500))
                .eraseToAnyPublisher()
                .async()
            let items = response.data ?? []
            
            return items.map { item in
                SutraItem(
                    id: item.id,
                    sutraId: item.sutraId,
                    title: item.title,
                    description: item.description,
                    originalLyricId: item.originalLyricId,
                    explanationLyricId: item.explanationLyricId,
                    audioId: item.audioId,
                    lesson: item.lesson,
                    playedCount: item.playedCount,
                    duration: item.duration,
                    createdAt: item.createdAt,
                    isVideo: item.isVideo,
                    audio: item.audio.map { $0.hasPrefix("http") ? $0 : "\(ossBaseUrl)\($0)" }
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
