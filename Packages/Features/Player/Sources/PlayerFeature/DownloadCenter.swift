import Foundation
import NetworkKit

public struct DownloadRecord: Equatable, Identifiable, Sendable {
    public enum State: Equatable, Sendable {
        case queued
        case downloading(Double)
        case paused
        case finished
        case failed(String)
    }

    public var id: String
    public var title: String
    public var sutraId: String
    public var albumName: String
    public var imageURL: String?
    public var lesson: Int
    public var remoteURL: URL?
    public var state: State

    public init(
        id: String,
        title: String,
        sutraId: String = "",
        albumName: String = "",
        imageURL: String? = nil,
        lesson: Int = 0,
        remoteURL: URL? = nil,
        state: State
    ) {
        self.id = id
        self.title = title
        self.sutraId = sutraId
        self.albumName = albumName
        self.imageURL = imageURL
        self.lesson = lesson
        self.remoteURL = remoteURL
        self.state = state
    }

    public var itemId: String { id }
    public var isFinished: Bool { state == .finished }
}

/// What the caller knows about an episode when it asks for a download.
public struct DownloadRequest: Equatable, Sendable {
    public var itemId: String
    public var title: String
    public var sutraId: String
    public var albumName: String
    public var imageURL: String?
    public var lesson: Int
    public var remoteURL: URL

    public init(itemId: String, title: String, sutraId: String, albumName: String, imageURL: String?, lesson: Int, remoteURL: URL) {
        self.itemId = itemId
        self.title = title
        self.sutraId = sutraId
        self.albumName = albumName
        self.imageURL = imageURL
        self.lesson = lesson
        self.remoteURL = remoteURL
    }
}

public final class DownloadCenter: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    public static let shared = DownloadCenter()

    public var backgroundCompletion: (() -> Void)?
    /// Signed audio URLs expire, so restarting a task asks for a fresh one first.
    public var urlRefresher: (@Sendable (DownloadRecord) async -> URL?)?
    private let lock = NSLock()
    private var records: [String: DownloadRecord] = [:]
    private var taskIDs: [Int: String] = [:]
    private var tasks: [String: URLSessionDownloadTask] = [:]
    private var continuations: [UUID: AsyncStream<[DownloadRecord]>.Continuation] = [:]
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "cn.org.htz.next.downloads")
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HTZDownloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    private var metaURL: URL {
        folder.appendingPathComponent("meta.json")
    }

    private override init() {
        super.init()
        loadPersisted()
        urlRefresher = { record in
            guard !record.sutraId.isEmpty else { return nil }
            return try? await LibraryAPI.fileURL(sutraId: record.sutraId, itemId: record.id).audioURL
        }
    }

    public func recordsSnapshot() -> [DownloadRecord] {
        lock.lock()
        defer { lock.unlock() }
        return sortedRecords()
    }

    public func updates() -> AsyncStream<[DownloadRecord]> {
        AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            continuations[id] = continuation
            let snapshot = sortedRecords()
            lock.unlock()
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.continuations[id] = nil
                self?.lock.unlock()
            }
        }
    }

    public func localFile(for itemId: String) -> URL? {
        let url = fileURL(itemId)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    public func download(_ request: DownloadRequest) {
        let record = DownloadRecord(
            id: request.itemId,
            title: request.title,
            sutraId: request.sutraId,
            albumName: request.albumName,
            imageURL: request.imageURL,
            lesson: request.lesson,
            remoteURL: request.remoteURL,
            state: .queued
        )
        if localFile(for: request.itemId) != nil {
            set(record, state: .finished)
            persist()
            return
        }
        lock.lock()
        let existing = tasks[request.itemId]
        lock.unlock()
        if let existing {
            existing.resume()
            set(record, state: .downloading(0))
            return
        }
        set(record, state: .queued)
        start(itemId: request.itemId, url: request.remoteURL)
        persist()
    }

    public func pause(itemId: String) {
        lock.lock()
        let task = tasks[itemId]
        lock.unlock()
        task?.suspend()
        transition(itemId, to: .paused)
        persist()
    }

    public func resume(itemId: String) {
        lock.lock()
        let task = tasks[itemId]
        let record = records[itemId]
        lock.unlock()
        if let task {
            task.resume()
            transition(itemId, to: .downloading(0))
            return
        }
        guard let record else { return }
        transition(itemId, to: .queued)
        let refresh = urlRefresher
        Task {
            let fresh = await refresh?(record)
            guard let url = fresh ?? record.remoteURL else {
                self.transition(itemId, to: .failed("获取下载地址失败"))
                return
            }
            if fresh != nil {
                self.mutate(itemId) { existing in
                    var updated = existing ?? record
                    updated.remoteURL = url
                    return updated
                }
            }
            self.start(itemId: itemId, url: url)
            self.persist()
        }
    }

    public func cancel(itemId: String) {
        lock.lock()
        let task = tasks[itemId]
        tasks[itemId] = nil
        lock.unlock()
        task?.cancel()
        transition(itemId, to: .failed("已取消"))
        persist()
    }

    public func delete(itemId: String) {
        delete(itemIds: [itemId])
    }

    public func delete(itemIds: [String]) {
        lock.lock()
        let removed = itemIds.compactMap { tasks.removeValue(forKey: $0) }
        itemIds.forEach { records[$0] = nil }
        let snapshot = sortedRecords()
        let continuations = continuations.values
        lock.unlock()
        removed.forEach { $0.cancel() }
        itemIds.forEach { try? FileManager.default.removeItem(at: fileURL($0)) }
        continuations.forEach { $0.yield(snapshot) }
        persist()
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let itemId = itemId(for: downloadTask) else { return }
        let fraction = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        transition(itemId, to: .downloading(fraction))
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let itemId = itemId(for: downloadTask) else { return }
        let destination = fileURL(itemId)
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            transition(itemId, to: .finished)
        } catch {
            transition(itemId, to: .failed(error.localizedDescription))
        }
        persist()
        lock.lock()
        tasks[itemId] = nil
        lock.unlock()
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, let itemId = itemId(for: task) else { return }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain, ns.code == NSURLErrorCancelled { return }
        transition(itemId, to: .failed(error.localizedDescription))
        lock.lock()
        tasks[itemId] = nil
        lock.unlock()
        persist()
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let completion = backgroundCompletion
        backgroundCompletion = nil
        DispatchQueue.main.async { completion?() }
    }

    private func start(itemId: String, url: URL) {
        let task = session.downloadTask(with: url)
        lock.lock()
        taskIDs[task.taskIdentifier] = itemId
        tasks[itemId] = task
        lock.unlock()
        task.resume()
    }

    private func fileURL(_ itemId: String) -> URL {
        folder.appendingPathComponent("\(itemId).mp3")
    }

    private func itemId(for task: URLSessionTask) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return taskIDs[task.taskIdentifier]
    }

    /// Caller must hold `lock`.
    private func sortedRecords() -> [DownloadRecord] {
        records.values.sorted {
            if $0.albumName != $1.albumName { return $0.albumName < $1.albumName }
            if $0.lesson != $1.lesson { return $0.lesson < $1.lesson }
            return $0.title < $1.title
        }
    }

    private func set(_ record: DownloadRecord, state: DownloadRecord.State) {
        var record = record
        record.state = state
        mutate(record.id) { _ in record }
    }

    private func transition(_ itemId: String, to state: DownloadRecord.State) {
        mutate(itemId) { existing in
            var record = existing ?? DownloadRecord(id: itemId, title: itemId, state: state)
            record.state = state
            return record
        }
    }

    private func mutate(_ itemId: String, _ change: (DownloadRecord?) -> DownloadRecord) {
        lock.lock()
        records[itemId] = change(records[itemId])
        let snapshot = sortedRecords()
        let continuations = continuations.values
        lock.unlock()
        continuations.forEach { $0.yield(snapshot) }
    }

    private func loadPersisted() {
        if let data = try? Data(contentsOf: metaURL),
           let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for row in rows {
                guard let id = row["id"] as? String else { continue }
                let remote = (row["remoteURL"] as? String).flatMap(URL.init)
                let finished = FileManager.default.fileExists(atPath: fileURL(id).path)
                guard finished || remote != nil else { continue }
                records[id] = DownloadRecord(
                    id: id,
                    title: row["title"] as? String ?? id,
                    sutraId: row["sutraId"] as? String ?? "",
                    albumName: row["albumName"] as? String ?? "",
                    imageURL: row["imageURL"] as? String,
                    lesson: row["lesson"] as? Int ?? 0,
                    remoteURL: remote,
                    state: finished ? .finished : .paused
                )
            }
        }
        if let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "mp3" {
                let id = file.deletingPathExtension().lastPathComponent
                if records[id] == nil {
                    records[id] = DownloadRecord(id: id, title: id, state: .finished)
                }
            }
        }
    }

    private func persist() {
        lock.lock()
        let rows: [[String: Any]] = records.values.map { record in
            var row: [String: Any] = [
                "id": record.id,
                "title": record.title,
                "sutraId": record.sutraId,
                "albumName": record.albumName,
                "lesson": record.lesson
            ]
            if let image = record.imageURL { row["imageURL"] = image }
            if let remote = record.remoteURL?.absoluteString { row["remoteURL"] = remote }
            return row
        }
        lock.unlock()
        guard let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted]) else { return }
        try? data.write(to: metaURL, options: .atomic)
    }
}
