import Foundation

/// Device-side copy of the listen history, like Android's `HistoryManager`: a play is recorded
/// locally the moment it starts and shown right away, then synced to the server. Plays made while
/// the server is unreachable (typically downloaded episodes) stay pending and are merged into the
/// list until the server has them.
public final class LocalHistory: @unchecked Sendable {
    public static let shared = LocalHistory()

    struct Entry: Codable, Equatable {
        var itemId: String
        var sutraId: String
        var title: String
        var sutraName: String
        var cover: String
        var position: Int
        var createdAt: Int
        var serverId: String?
        /// The server accepted this play; it stays until a server list actually contains the episode.
        var uploaded: Bool?
    }

    struct Meta: Codable, Equatable {
        var sutraId: String
        var title: String
        var sutraName: String
    }

    private struct Snapshot: Codable {
        var pending: [Entry] = []
        var cache: [Entry] = []
        var meta: [String: Meta] = [:]
    }

    private let lock = NSLock()
    private var snapshot = Snapshot()
    private let fileURL: URL?
    private let now: @Sendable () -> Int

    /// `fileURL == nil` keeps everything in memory (tests).
    init(fileURL: URL? = LocalHistory.defaultFileURL(), now: @escaping @Sendable () -> Int = { Int(Date().timeIntervalSince1970) }) {
        self.fileURL = fileURL
        self.now = now
        if let fileURL, let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(Snapshot.self, from: data) {
            snapshot = saved
        }
    }

    private static func defaultFileURL() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("HTZListenHistory.json")
    }

    // MARK: Writing

    /// What the list needs to show an episode; remembered when playback starts.
    public func remember(itemId: String, sutraId: String, title: String, sutraName: String) {
        guard !itemId.isEmpty else { return }
        let meta = Meta(sutraId: sutraId, title: title, sutraName: sutraName)
        lock.lock()
        let changed = snapshot.meta[itemId] != meta
        if changed {
            snapshot.meta[itemId] = meta
            if snapshot.meta.count > 400 {
                let keep = Set(snapshot.pending.map(\.itemId) + snapshot.cache.map(\.itemId))
                snapshot.meta = snapshot.meta.filter { keep.contains($0.key) || $0.key == itemId }
            }
        }
        let data = changed ? encoded() : nil
        lock.unlock()
        write(data)
    }

    /// Records a play as pending; returns its timestamp, or nil when we cannot describe the episode.
    @discardableResult
    func record(itemId: String, position: Int) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        guard let meta = snapshot.meta[itemId] ?? cachedMeta(itemId) else { return nil }
        let stamp = now()
        let existing = snapshot.pending.first { $0.itemId == itemId }
        let entry = Entry(
            itemId: itemId,
            sutraId: meta.sutraId,
            title: meta.title,
            sutraName: meta.sutraName,
            cover: "",
            position: position,
            createdAt: stamp,
            serverId: existing?.serverId ?? snapshot.cache.first { $0.itemId == itemId }?.serverId
        )
        snapshot.pending.removeAll { $0.itemId == itemId }
        snapshot.pending.append(entry)
        write(encoded())
        return stamp
    }

    /// The server accepted this play. It is kept (so the list never loses it) until a server list
    /// shows the episode, see `storeServerRows`.
    func markSynced(itemId: String, upTo stamp: Int) {
        lock.lock()
        var changed = false
        for index in snapshot.pending.indices
        where snapshot.pending[index].itemId == itemId && snapshot.pending[index].createdAt <= stamp {
            snapshot.pending[index].uploaded = true
            changed = true
        }
        let data = changed ? encoded() : nil
        lock.unlock()
        write(data)
    }

    /// Plays the server has not accepted yet, old enough not to be an upload still in flight.
    func stalePending(olderThan seconds: Int) -> [(itemId: String, position: Int, stamp: Int)] {
        lock.lock()
        defer { lock.unlock() }
        let limit = now() - seconds
        return snapshot.pending
            .filter { $0.uploaded != true && $0.createdAt <= limit }
            .map { ($0.itemId, $0.position, $0.createdAt) }
    }

    /// Removes anything that refers to a deleted history row.
    func remove(id: String) {
        lock.lock()
        snapshot.pending.removeAll { $0.itemId == id || $0.serverId == id }
        snapshot.cache.removeAll { $0.itemId == id || $0.serverId == id }
        let data = encoded()
        lock.unlock()
        write(data)
    }

    func removeAll() {
        lock.lock()
        snapshot.pending = []
        snapshot.cache = []
        let data = encoded()
        lock.unlock()
        write(data)
    }

    // MARK: Reading

    /// Remembers the last list the server returned so it can still be shown offline.
    func storeServerRows(_ rows: [ListenHistoryItem]) {
        lock.lock()
        // Confirmed by the server (or long forgotten): no need to carry these locally any more.
        let listed = Set(rows.map(\.itemId))
        let expiry = now() - 24 * 3600
        snapshot.pending.removeAll { $0.uploaded == true && (listed.contains($0.itemId) || $0.createdAt < expiry) }
        snapshot.cache = rows.map {
            Entry(
                itemId: $0.itemId, sutraId: $0.sutraId, title: $0.title, sutraName: $0.sutraName,
                cover: $0.cover, position: $0.lastPosition, createdAt: $0.createdAt, serverId: $0.id
            )
        }
        for row in rows where !row.title.isEmpty {
            snapshot.meta[row.itemId] = Meta(sutraId: row.sutraId, title: row.title, sutraName: row.sutraName)
        }
        let data = encoded()
        lock.unlock()
        write(data)
    }

    func cachedRows() -> [ListenHistoryItem] {
        lock.lock()
        defer { lock.unlock() }
        return snapshot.cache.map(Self.item(from:))
    }

    /// Server rows plus the plays the server has not listed yet. Those are the newest plays by
    /// definition, so they go on top whatever the server clock says.
    func merged(with rows: [ListenHistoryItem]) -> [ListenHistoryItem] {
        lock.lock()
        let pending = snapshot.pending.sorted { $0.createdAt < $1.createdAt }
        lock.unlock()
        guard !pending.isEmpty else { return rows }

        var result = rows
        var fresh: [ListenHistoryItem] = []
        for entry in pending {
            if let index = result.firstIndex(where: { $0.itemId == entry.itemId }) {
                guard result[index].createdAt < entry.createdAt else { continue }
                result[index].lastPosition = entry.position
                result[index].createdAt = entry.createdAt
                fresh.append(result.remove(at: index))
            } else {
                fresh.append(Self.item(from: entry))
            }
        }
        return fresh.sortedNewestFirst() + result.sortedNewestFirst()
    }

    private static func item(from entry: Entry) -> ListenHistoryItem {
        ListenHistoryItem(
            id: entry.serverId ?? entry.itemId,
            sutraItemId: entry.itemId,
            sutraId: entry.sutraId,
            title: entry.title,
            sutraName: entry.sutraName,
            cover: entry.cover,
            lastPosition: entry.position,
            createdAt: entry.createdAt
        )
    }

    private func cachedMeta(_ itemId: String) -> Meta? {
        guard let row = snapshot.cache.first(where: { $0.itemId == itemId }), !row.title.isEmpty else { return nil }
        return Meta(sutraId: row.sutraId, title: row.title, sutraName: row.sutraName)
    }

    // MARK: Persistence (callers hold `lock` while encoding)

    private func encoded() -> Data? {
        try? JSONEncoder().encode(snapshot)
    }

    private func write(_ data: Data?) {
        guard let data, let fileURL else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
