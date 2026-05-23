import Foundation
import ComposableArchitecture
import HTZAudio

public struct PlayerClient {
    public var play: @Sendable (PlayerItem) async -> Void
    public var resume: @Sendable () async -> Void
    public var pause: @Sendable () async -> Void
    public var playerStateStream: @Sendable () -> AsyncStream<PlayerState>
}

extension PlayerClient: DependencyKey {
    public static let liveValue: Self = {
        let engine = AudioEngine.shared
        let sharedStream = engine.stateStream
        return Self(
            play: { item in await engine.play(item: item) },
            resume: { await engine.resume() },
            pause: { await engine.pause() },
            playerStateStream: { sharedStream }
        )
    }()
    
    // Provide a test value that does nothing
    public static let testValue = Self(
        play: { _ in },
        resume: {},
        pause: {},
        playerStateStream: { AsyncStream { _ in } }
    )
}

extension DependencyValues {
    public var playerClient: PlayerClient {
        get { self[PlayerClient.self] }
        set { self[PlayerClient.self] = newValue }
    }
}
