import Foundation

/// In-memory + on-disk cache for album chapter lists. Opening an album used to block on
/// `get/sutra/items` every time; showing a cached list first removes that wait on revisit.
public final class ItemsCache: @unchecked Sendable {
    public static let shared = ItemsCache()

    private let lock = NSLock()
    private var memory: [String: Entry] = [:]
    private let directory: URL
    /// Fresh enough to show without a loading spinner; network still refreshes in the background.
    private let maxAge: TimeInterval = 7 * 24 * 60 * 60

    private struct Entry {
        var items: [SutraItem]
        var savedAt: Date
    }

    private init() {
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directory = root.appendingPathComponent("htz.items.cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func get(_ sutraId: String) -> [SutraItem]? {
        lock.lock()
        if let entry = memory[sutraId], Date().timeIntervalSince(entry.savedAt) < maxAge {
            lock.unlock()
            return entry.items
        }
        lock.unlock()

        let url = fileURL(sutraId)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(DiskPayload.self, from: data),
              Date().timeIntervalSince(decoded.savedAt) < maxAge else { return nil }

        lock.lock()
        memory[sutraId] = Entry(items: decoded.items, savedAt: decoded.savedAt)
        lock.unlock()
        return decoded.items
    }

    public func set(_ items: [SutraItem], for sutraId: String) {
        let now = Date()
        lock.lock()
        memory[sutraId] = Entry(items: items, savedAt: now)
        lock.unlock()

        let payload = DiskPayload(items: items, savedAt: now)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL(sutraId), options: .atomic)
    }

    private func fileURL(_ sutraId: String) -> URL {
        let safe = sutraId.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? sutraId
        return directory.appendingPathComponent("\(safe).json")
    }

    private struct DiskPayload: Codable {
        var items: [SutraItem]
        var savedAt: Date
    }
}
