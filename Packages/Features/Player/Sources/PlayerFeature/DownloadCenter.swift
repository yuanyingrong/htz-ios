import Foundation

public struct DownloadRecord: Equatable, Identifiable, Sendable {
    public enum State: Equatable, Sendable {
        case queued
        case downloading(Double)
        case finished
        case failed(String)
    }

    public var id: String
    public var title: String
    public var state: State

    public init(id: String, title: String, state: State) {
        self.id = id
        self.title = title
        self.state = state
    }
}

public final class DownloadCenter: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    public static let shared = DownloadCenter()

    public var backgroundCompletion: (() -> Void)?
    private let lock = NSLock()
    private var records: [String: DownloadRecord] = [:]
    private var taskIDs: [Int: String] = [:]
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

    public func download(itemId: String, title: String, remoteURL: URL) {
        if localFile(for: itemId) != nil {
            set(DownloadRecord(id: itemId, title: title, state: .finished))
            return
        }
        set(DownloadRecord(id: itemId, title: title, state: .queued))
        let task = session.downloadTask(with: remoteURL)
        lock.lock()
        taskIDs[task.taskIdentifier] = itemId
        lock.unlock()
        task.resume()
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let itemId = itemId(for: downloadTask) else { return }
        let fraction = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        update(itemId) { DownloadRecord(id: itemId, title: $0?.title ?? itemId, state: .downloading(fraction)) }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let itemId = itemId(for: downloadTask) else { return }
        let destination = folder.appendingPathComponent("\(itemId).mp3")
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            update(itemId) { DownloadRecord(id: itemId, title: $0?.title ?? itemId, state: .finished) }
        } catch {
            update(itemId) { DownloadRecord(id: itemId, title: $0?.title ?? itemId, state: .failed(error.localizedDescription)) }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, let itemId = itemId(for: task) else { return }
        update(itemId) { DownloadRecord(id: itemId, title: $0?.title ?? itemId, state: .failed(error.localizedDescription)) }
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
}
