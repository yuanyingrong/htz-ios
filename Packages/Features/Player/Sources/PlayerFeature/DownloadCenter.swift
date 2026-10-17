import Foundation

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
    public var sutraId: String?
    public var remoteURL: URL?
    public var state: State

    public init(id: String, title: String, sutraId: String? = nil, remoteURL: URL? = nil, state: State) {
        self.id = id
        self.title = title
        self.sutraId = sutraId
        self.remoteURL = remoteURL
        self.state = state
    }
}

public final class DownloadCenter: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    public static let shared = DownloadCenter()

    public var backgroundCompletion: (() -> Void)?
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
    }

    public func recordsSnapshot() -> [DownloadRecord] {
        lock.lock()
        defer { lock.unlock() }
        return records.values.sorted { $0.title < $1.title }
    }

    public func updates() -> AsyncStream<[DownloadRecord]> {
        AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            continuations[id] = continuation
            let snapshot = records.values.sorted { $0.title < $1.title }
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
        let url = folder.appendingPathComponent("\(itemId).mp3")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    public func download(itemId: String, title: String, remoteURL: URL, sutraId: String? = nil) {
        if localFile(for: itemId) != nil {
            set(DownloadRecord(id: itemId, title: title, sutraId: sutraId, remoteURL: remoteURL, state: .finished))
            persist()
            return
        }
        lock.lock()
        if let existing = tasks[itemId] {
            lock.unlock()
            existing.resume()
            update(itemId) {
                DownloadRecord(
                    id: itemId,
                    title: $0?.title ?? title,
                    sutraId: sutraId ?? $0?.sutraId,
                    remoteURL: remoteURL,
                    state: .downloading(0)
                )
            }
            return
        }
        lock.unlock()
        set(DownloadRecord(id: itemId, title: title, sutraId: sutraId, remoteURL: remoteURL, state: .queued))
        let task = session.downloadTask(with: remoteURL)
        lock.lock()
        taskIDs[task.taskIdentifier] = itemId
        tasks[itemId] = task
        lock.unlock()
        task.resume()
        persist()
    }

    public func pause(itemId: String) {
        lock.lock()
        let task = tasks[itemId]
        lock.unlock()
        task?.suspend()
        update(itemId) {
            DownloadRecord(
                id: itemId,
                title: $0?.title ?? itemId,
                sutraId: $0?.sutraId,
                remoteURL: $0?.remoteURL,
                state: .paused
            )
        }
        persist()
    }

    public func resume(itemId: String) {
        lock.lock()
        let task = tasks[itemId]
        let record = records[itemId]
        lock.unlock()
        if let task {
            task.resume()
            update(itemId) {
                DownloadRecord(
                    id: itemId,
                    title: $0?.title ?? itemId,
                    sutraId: $0?.sutraId,
                    remoteURL: $0?.remoteURL,
                    state: .downloading(0)
                )
            }
            return
        }
        if let url = record?.remoteURL {
            download(itemId: itemId, title: record?.title ?? itemId, remoteURL: url, sutraId: record?.sutraId)
        }
    }

    public func cancel(itemId: String) {
        lock.lock()
        let task = tasks[itemId]
        tasks[itemId] = nil
        lock.unlock()
        task?.cancel()
        update(itemId) {
            DownloadRecord(
                id: itemId,
                title: $0?.title ?? itemId,
                sutraId: $0?.sutraId,
                remoteURL: $0?.remoteURL,
                state: .failed("已取消")
            )
        }
        persist()
    }

    public func delete(itemId: String) {
        lock.lock()
        let task = tasks[itemId]
        tasks[itemId] = nil
        records[itemId] = nil
        let snapshot = records.values.sorted { $0.title < $1.title }
        let continuations = continuations.values
        lock.unlock()
        task?.cancel()
        try? FileManager.default.removeItem(at: folder.appendingPathComponent("\(itemId).mp3"))
        continuations.forEach { $0.yield(snapshot) }
        persist()
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let itemId = itemId(for: downloadTask) else { return }
        let fraction = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        update(itemId) {
            DownloadRecord(
                id: itemId,
                title: $0?.title ?? itemId,
                sutraId: $0?.sutraId,
                remoteURL: $0?.remoteURL,
                state: .downloading(fraction)
            )
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let itemId = itemId(for: downloadTask) else { return }
        let destination = folder.appendingPathComponent("\(itemId).mp3")
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            update(itemId) {
                DownloadRecord(
                    id: itemId,
                    title: $0?.title ?? itemId,
                    sutraId: $0?.sutraId,
                    remoteURL: $0?.remoteURL,
                    state: .finished
                )
            }
            persist()
        } catch {
            update(itemId) {
                DownloadRecord(
                    id: itemId,
                    title: $0?.title ?? itemId,
                    sutraId: $0?.sutraId,
                    remoteURL: $0?.remoteURL,
                    state: .failed(error.localizedDescription)
                )
            }
            persist()
        }
        lock.lock()
        tasks[itemId] = nil
        lock.unlock()
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, let itemId = itemId(for: task) else { return }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain, ns.code == NSURLErrorCancelled { return }
        update(itemId) {
            DownloadRecord(
                id: itemId,
                title: $0?.title ?? itemId,
                sutraId: $0?.sutraId,
                remoteURL: $0?.remoteURL,
                state: .failed(error.localizedDescription)
            )
        }
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

    private func itemId(for task: URLSessionTask) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return taskIDs[task.taskIdentifier]
    }

    private func set(_ record: DownloadRecord) {
        update(record.id) { _ in record }
    }

    private func update(_ itemId: String, _ mutate: (DownloadRecord?) -> DownloadRecord) {
        lock.lock()
        let next = mutate(records[itemId])
        records[itemId] = next
        let snapshot = records.values.sorted { $0.title < $1.title }
        let continuations = continuations.values
        lock.unlock()
        continuations.forEach { $0.yield(snapshot) }
    }

    private func loadPersisted() {
        if let data = try? Data(contentsOf: metaURL),
           let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for row in rows {
                guard let id = row["id"] as? String else { continue }
                let title = row["title"] as? String ?? id
                let sutraId = row["sutraId"] as? String
                let remote = (row["remoteURL"] as? String).flatMap(URL.init)
                if FileManager.default.fileExists(atPath: folder.appendingPathComponent("\(id).mp3").path) {
                    records[id] = DownloadRecord(id: id, title: title, sutraId: sutraId, remoteURL: remote, state: .finished)
                } else if let remote {
                    records[id] = DownloadRecord(id: id, title: title, sutraId: sutraId, remoteURL: remote, state: .failed("未完成"))
                }
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
            var row: [String: Any] = ["id": record.id, "title": record.title]
            if let sutraId = record.sutraId { row["sutraId"] = sutraId }
            if let remote = record.remoteURL?.absoluteString { row["remoteURL"] = remote }
            return row
        }
        lock.unlock()
        guard let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted]) else { return }
        try? data.write(to: metaURL, options: .atomic)
    }
}
