import Foundation
import UIKit

/// Shared cover/thumbnail cache. SwiftUI `AsyncImage` does not share bytes across views, so every
/// album-row cell would re-download the same cover; this coalesces in-flight loads and keeps a
/// memory + disk (`URLCache`) store keyed by URL.
public enum HTZImageCache {
    public static func image(for url: URL) async -> UIImage? {
        await Store.shared.image(for: url)
    }

    public static func cachedImage(for url: URL) -> UIImage? {
        Store.shared.memoryImage(for: url)
    }
}

private final class Store: @unchecked Sendable {
    static let shared = Store()

    private let memory = NSCache<NSURL, UIImage>()
    private let lock = NSLock()
    private var inflight: [URL: Task<UIImage?, Never>] = [:]
    private let session: URLSession

    private init() {
        memory.countLimit = 200
        memory.totalCostLimit = 80 * 1024 * 1024

        let cache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "htz.image.cache"
        )
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 20
        session = URLSession(configuration: config)
    }

    func memoryImage(for url: URL) -> UIImage? {
        memory.object(forKey: url as NSURL)
    }

    func image(for url: URL) async -> UIImage? {
        if let cached = memoryImage(for: url) { return cached }

        let task = takeOrCreateTask(for: url)
        return await task.value
    }

    private func takeOrCreateTask(for url: URL) -> Task<UIImage?, Never> {
        lock.lock()
        if let existing = inflight[url] {
            lock.unlock()
            return existing
        }
        let created = Task<UIImage?, Never> {
            defer { clearInflight(url) }
            return await download(url)
        }
        inflight[url] = created
        lock.unlock()
        return created
    }

    private func clearInflight(_ url: URL) {
        lock.lock()
        inflight[url] = nil
        lock.unlock()
    }

    private func download(_ url: URL) async -> UIImage? {
        do {
            let (data, response) = try await session.data(for: URLRequest(url: url))
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let image = UIImage(data: data) else { return nil }
            memory.setObject(image, forKey: url as NSURL, cost: data.count)
            return image
        } catch {
            return nil
        }
    }
}
