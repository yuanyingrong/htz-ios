import Foundation

/// Fans player state out to every subscriber. A single AsyncStream can only be
/// consumed once, so a second subscribe (SwiftUI onAppear) would otherwise go deaf.
public final class PlaybackBroadcaster: @unchecked Sendable {
    public static let shared = PlaybackBroadcaster()

    private let lock = NSLock()
    private var listeners: [UUID: AsyncStream<PlayerState>.Continuation] = [:]
    private var latest = PlayerState()

    public func makeStream() -> AsyncStream<PlayerState> {
        AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            listeners[id] = continuation
            let snapshot = latest
            lock.unlock()
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.lock()
                self.listeners[id] = nil
                self.lock.unlock()
            }
        }
    }

    public func yield(_ state: PlayerState) {
        lock.lock()
        latest = state
        let listeners = Array(listeners.values)
        lock.unlock()
        for listener in listeners {
            listener.yield(state)
        }
    }
}
