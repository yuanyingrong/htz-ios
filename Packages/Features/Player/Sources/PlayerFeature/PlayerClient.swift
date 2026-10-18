import Foundation
import ComposableArchitecture
import HTZAudio

public struct PlayerClient {
    public var play: @Sendable (PlayerItem) async -> Void
    public var resume: @Sendable () async -> Void
    public var pause: @Sendable () async -> Void
    public var stop: @Sendable () async -> Void
    public var seek: @Sendable (Double) async -> Void
    public var setRate: @Sendable (Double) async -> Void
    public var playerStateStream: @Sendable () -> AsyncStream<PlayerState>
}

extension PlayerClient: DependencyKey {
    public static let liveValue = Self(
        play: { item in await AudioEngine.shared.play(item: item) },
        resume: { await AudioEngine.shared.resume() },
        pause: { await AudioEngine.shared.pause() },
        stop: { await AudioEngine.shared.stop() },
        seek: { seconds in await AudioEngine.shared.seek(to: seconds) },
        setRate: { rate in await AudioEngine.shared.setRate(rate) },
        playerStateStream: { PlaybackBroadcaster.shared.makeStream() }
    )
    
    public static let testValue = Self(
        play: { _ in },
        resume: {},
        pause: {},
        stop: {},
        seek: { _ in },
        setRate: { _ in },
        playerStateStream: { AsyncStream { $0.finish() } }
    )
}

extension DependencyValues {
    public var playerClient: PlayerClient {
        get { self[PlayerClient.self] }
        set { self[PlayerClient.self] = newValue }
    }
}
