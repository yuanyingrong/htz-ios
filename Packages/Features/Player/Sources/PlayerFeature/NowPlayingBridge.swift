import Foundation
import MediaPlayer
import UIKit
import ComposableArchitecture
import HTZAudio

public enum RemoteCommand: Equatable, Sendable {
    case play
    case pause
    case next
    case previous
    case seek(Double)
}

public struct NowPlayingClient: Sendable {
    public var commands: @Sendable () -> AsyncStream<RemoteCommand>
    public var update: @Sendable (PlayerItem?, Double, Double, Double, Bool) async -> Void

    public init(
        commands: @escaping @Sendable () -> AsyncStream<RemoteCommand>,
        update: @escaping @Sendable (PlayerItem?, Double, Double, Double, Bool) async -> Void
    ) {
        self.commands = commands
        self.update = update
    }
}

extension NowPlayingClient: DependencyKey {
    public static let liveValue: NowPlayingClient = {
        let bridge = NowPlayingBridge()
        return NowPlayingClient(
            commands: { bridge.commands() },
            update: { item, time, duration, rate, isPlaying in
                await bridge.update(item: item, time: time, duration: duration, rate: rate, isPlaying: isPlaying)
            }
        )
    }()

    public static let testValue = NowPlayingClient(
        commands: { AsyncStream { $0.finish() } },
        update: { _, _, _, _, _ in }
    )
}

extension DependencyValues {
    public var nowPlayingClient: NowPlayingClient {
        get { self[NowPlayingClient.self] }
        set { self[NowPlayingClient.self] = newValue }
    }
}

private final class NowPlayingBridge: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: AsyncStream<RemoteCommand>.Continuation?
    private var didRegister = false

    func commands() -> AsyncStream<RemoteCommand> {
        AsyncStream { continuation in
            lock.lock()
            self.continuation = continuation
            lock.unlock()
            registerIfNeeded()
        }
    }

    func update(item: PlayerItem?, time: Double, duration: Double, rate: Double, isPlaying: Bool) async {
        var info: [String: Any] = [
            MPNowPlayingInfoPropertyElapsedPlaybackTime: time,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? rate : 0
        ]
        if let item {
            info[MPMediaItemPropertyTitle] = item.title
            if let artist = item.artist {
                info[MPMediaItemPropertyArtist] = artist
                info[MPMediaItemPropertyAlbumTitle] = artist
            }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        if let url = item?.imageUrl {
            Task { await loadArtwork(url) }
        }
    }

    private func loadArtwork(_ url: URL) async {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return }
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func registerIfNeeded() {
        lock.lock()
        let shouldRegister = !didRegister
        didRegister = true
        lock.unlock()
        guard shouldRegister else { return }
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            self?.yield(.play)
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.yield(.pause)
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.yield(.next)
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.yield(.previous)
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let position = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime else {
                return .commandFailed
            }
            self?.yield(.seek(position))
            return .success
        }
    }

    private func yield(_ command: RemoteCommand) {
        lock.lock()
        continuation?.yield(command)
        lock.unlock()
    }
}
