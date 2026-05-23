import Foundation
import ComposableArchitecture
import HTZAudio
import Combine
import SwiftUI

@Reducer
public struct PlayerFeature {
    @ObservableState
    public struct State: Equatable {
        public var currentItem: PlayerItem?
        public var isPlaying: Bool = false
        public var currentTime: Double = 0
        public var duration: Double = 0
        public var error: String?
        public var progress: Double {
            guard duration > 0 else { return 0 }
            return currentTime / duration
        }
        public init() {}
    }
    
    public enum Action: Equatable {
        case play(PlayerItem)
        case playButtonTapped
        case pauseButtonTapped
        case playerStateUpdated(PlayerState)
        case subscribeToPlayerState
    }
    
    @Dependency(\.playerClient) var playerClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .play(item):
                return .run { _ in
                    await playerClient.play(item)
                }
                
            case .playButtonTapped:
                return .run { _ in
                    await playerClient.resume()
                }
                
            case .pauseButtonTapped:
                return .run { _ in
                    await playerClient.pause()
                }
                
            case let .playerStateUpdated(newState):
                state.currentItem = newState.currentItem
                state.isPlaying = newState.isPlaying
                state.currentTime = newState.currentTime
                state.duration = newState.duration
                state.error = newState.error
                return .none
                
            case .subscribeToPlayerState:
                return .run { send in
                    for await playerState in self.playerClient.playerStateStream() {
                        await send(.playerStateUpdated(playerState))
                    }
                }
                .cancellable(id: PlayerClientCancellable())
            }
        }
    }
}

private struct PlayerClientCancellable: Hashable {}

// MARK: - Environment Key

public struct PlayerStoreEnvironmentKey: EnvironmentKey {
    public static let defaultValue: StoreOf<PlayerFeature> = Store(
        initialState: PlayerFeature.State()
    ) {
        PlayerFeature()
    }
}

extension EnvironmentValues {
    public var playerStore: StoreOf<PlayerFeature> {
        get { self[PlayerStoreEnvironmentKey.self] }
        set { self[PlayerStoreEnvironmentKey.self] = newValue }
    }
}
