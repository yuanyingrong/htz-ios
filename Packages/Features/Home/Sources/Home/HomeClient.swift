import Foundation
import ComposableArchitecture
import NetworkKit
import Combine

public struct HomeClient {
    public var getBanners: @Sendable () async throws -> [Banner]
    public var getAlbums: @Sendable () async throws -> [Album]
    public var getSutraItems: @Sendable (String) async throws -> [SutraItem]
    public var getSutraCoverURL: @Sendable (_ sutraId: String) async throws -> String
    public var getSutraItemFileURL: @Sendable (_ sutraId: String, _ sutraItemId: String) async throws -> SutraItemFileURLResponse
}

extension HomeClient: DependencyKey {
    private static let ossBaseUrl = "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/"
    
    // In-memory cache for resolved signed cover URLs: [sutraId: (url, expiryDate)]
    private final class CacheHolder: @unchecked Sendable {
        static let shared = CacheHolder()
        private let lock = NSLock()
        private var cache: [String: (url: String, expireAt: Date)] = [:]
        
        func get(for sutraId: String) -> String? {
            lock.lock()
            defer { lock.unlock() }
            if let entry = cache[sutraId], entry.expireAt > Date() {
                return entry.url
            }
            return nil
        }
        
        func set(url: String, for sutraId: String, expireSeconds: Int) {
            lock.lock()
            defer { lock.unlock() }
            let expireAt = Date().addingTimeInterval(TimeInterval(max(60, expireSeconds - 60)))
            cache[sutraId] = (url, expireAt)
        }
    }
    
    private static func resolveImageUrl(_ path: String?) -> String? {
        guard let path = path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return path
        }
        return "\(ossBaseUrl)\(path)"
    }
    
    private static func fetchCoverURL(for sutraId: String) async -> String? {
        if let cached = CacheHolder.shared.get(for: sutraId) {
            return cached
        }
        let manager = NetworkManager<HTZAPI>()
        do {
            let response: APIResponse<SutraCoverURLResponse> = try await manager.request(.sutraCoverURL(sutraId: sutraId, expireSeconds: 3600))
                .eraseToAnyPublisher()
                .async()
            if let signedUrl = response.data?.signedUrl, !signedUrl.isEmpty {
                let expireSeconds = response.data?.expireSeconds ?? 3600
                CacheHolder.shared.set(url: signedUrl, for: sutraId, expireSeconds: expireSeconds)
                return signedUrl
            }
        } catch {
            return nil
        }
        return nil
    }
    
    public static let liveValue = Self(
        getBanners: {
            let manager = NetworkManager<HTZAPI>()
            let response: APIResponse<[Album]> = try await manager.request(.albums)
                .eraseToAnyPublisher()
                .async()
            let albums = response.data ?? []
            
            return try await withThrowingTaskGroup(of: Banner.self) { group in
                for album in albums.prefix(3) {
                    group.addTask {
                        let signedCover = await fetchCoverURL(for: album.id)
                        let imageUrl = signedCover ?? resolveImageUrl(album.imageUrl)
                        return Banner(id: album.id, name: album.name, description: "", imageUrl: imageUrl, sort: "0")
                    }
                }
                var results: [Banner] = []
                for try await banner in group {
                    results.append(banner)
                }
                return results
            }
        },
        getAlbums: {
            let manager = NetworkManager<HTZAPI>()
            let response: APIResponse<[Album]> = try await manager.request(.albums)
                .eraseToAnyPublisher()
                .async()
            let albums = response.data ?? []
            
            return try await withThrowingTaskGroup(of: (Int, Album).self) { group in
                for (index, album) in albums.enumerated() {
                    group.addTask {
                        let signedCover = await fetchCoverURL(for: album.id)
                        let resolved = signedCover ?? resolveImageUrl(album.imageUrl)
                        return (index, Album(
                            id: album.id,
                            name: album.name,
                            imageUrl: resolved,
                            description: album.description,
                            isPaid: album.isPaid,
                            price: album.price,
                            isPurchased: album.isPurchased,
                            paidUrl: album.paidUrl
                        ))
                    }
                }
                var results: [(Int, Album)] = []
                for try await alb in group {
                    results.append(alb)
                }
                return results.sorted { $0.0 < $1.0 }.map(\.1)
            }
        },
        getSutraItems: { sutraId in
            let manager = NetworkManager<HTZAPI>()
            let response: APIResponse<[SutraItem]> = try await manager.request(.items(sutraId: sutraId, pageIndex: 0, pageSize: 500))
                .eraseToAnyPublisher()
                .async()
            let items = response.data ?? []
            
            return items.map { item in
                let resolvedAudio: String? = {
                    if let aid = item.audioId, !aid.isEmpty {
                        return "\(ossBaseUrl)\(aid)"
                    }
                    if let audio = item.audio, !audio.isEmpty {
                        return "http://htzshanghai.top/resources/audios/\(sutraId)/\(audio)"
                    }
                    return nil
                }()
                return SutraItem(
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
                    isTrial: item.isTrial,
                    audio: resolvedAudio
                )
            }
        },
        getSutraCoverURL: { sutraId in
            if let url = await fetchCoverURL(for: sutraId) {
                return url
            }
            throw NetworkError.apiError("No cover URL returned")
        },
        getSutraItemFileURL: { sutraId, sutraItemId in
            let manager = NetworkManager<HTZAPI>()
            let response: APIResponse<SutraItemFileURLResponse> = try await manager.request(.sutraItemFileURL(sutraId: sutraId, sutraItemId: sutraItemId, expireSeconds: 3600))
                .eraseToAnyPublisher()
                .async()
            guard let fileData = response.data else {
                throw NetworkError.apiError(response.msg ?? "Failed to get file URL")
            }
            return fileData
        }
    )
}

extension DependencyValues {
    public var homeClient: HomeClient {
        get { self[HomeClient.self] }
        set { self[HomeClient.self] = newValue }
    }
}


