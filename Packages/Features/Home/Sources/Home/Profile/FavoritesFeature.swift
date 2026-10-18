import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature
import SwiftUI

@Reducer
public struct FavoritesFeature {
    @ObservableState
    public struct State: Equatable {
        public var items: [FavoriteItem] = []
        public var covers: [String: String] = [:]
        public var isLoading = false
        public var toast: String?
        public var isClearConfirmPresented = false

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case loaded([FavoriteItem])
        case coversLoaded([String: String])
        case failed
        case play(FavoriteItem)
        case delete(FavoriteItem)
        case deleted(String)
        case clearAllTapped
        case clearAllConfirmed
        case cleared
        case toast(String)
    }

    @Dependency(\.library) var library
    @Dependency(\.playback) var playback

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.isLoading = state.items.isEmpty
                return .run { send in
                    do {
                        await send(.loaded(try await library.favorites()))
                    } catch {
                        await send(.failed)
                    }
                }

            case let .loaded(items):
                state.isLoading = false
                state.items = items
                let missing = Set(items.map(\.sutraId)).subtracting(state.covers.keys)
                return .run { send in
                    await send(.coversLoaded(await CoverLookup.signed(for: missing, library: library)))
                }

            case let .coversLoaded(covers):
                state.covers.merge(covers) { _, new in new }
                return .none

            case .failed:
                state.isLoading = false
                state.toast = "加载失败"
                return .none

            case let .play(item):
                let covers = state.covers
                let tracks = state.items.map { favorite in
                    var track = QueueTrack(favorite: favorite)
                    if let cover = covers[favorite.sutraId] { track.imageUrl = URL(string: cover) }
                    return track
                }
                let index = state.items.firstIndex(of: item) ?? 0
                return .run { _ in await playback.play(tracks, index, true, 0) }

            case let .delete(item):
                return .run { send in
                    do {
                        try await library.deleteFavorite(item.serverId)
                        await send(.deleted(item.id))
                    } catch {
                        await send(.toast("取消收藏失败"))
                    }
                }

            case let .deleted(id):
                state.items.removeAll { $0.id == id }
                return .none

            case .clearAllTapped:
                state.isClearConfirmPresented = true
                return .none

            case .clearAllConfirmed:
                return .run { send in
                    do {
                        try await library.deleteAllFavorites()
                        await send(.cleared)
                    } catch {
                        await send(.toast("清空失败"))
                    }
                }

            case .cleared:
                state.items = []
                state.toast = "已清空"
                return .none

            case let .toast(message):
                state.toast = message
                return .none
            }
        }
    }
}

struct FavoritesView: View {
    @Perception.Bindable var store: StoreOf<FavoritesFeature>

    var body: some View {
        WithPerceptionTracking {
            List {
                ForEach(store.items) { item in
                    Button {
                        store.send(.play(item))
                    } label: {
                        LibraryTrackRow(
                            title: item.title.isEmpty ? "未命名章节" : item.title,
                            subtitle: item.sutraName,
                            cover: CoverLookup.url(store.covers[item.sutraId], fallback: item.cover)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .swipeActions {
                        Button("取消收藏", role: .destructive) { store.send(.delete(item)) }
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if store.isLoading {
                    ProgressView()
                } else if store.items.isEmpty {
                    HTZEmptyView("还没有收藏", icon: "heart")
                }
            }
            .refreshable { store.send(.onAppear) }
            .htzPage("我的收藏")
            .toolbar {
                if !store.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("清空") { store.send(.clearAllTapped) }
                            .foregroundColor(HTZColor.title)
                    }
                }
            }
            .confirmationDialog("确定清空全部收藏？", isPresented: $store.isClearConfirmPresented, titleVisibility: .visible) {
                Button("清空", role: .destructive) { store.send(.clearAllConfirmed) }
            }
            .htzToast($store.toast)
            .onAppear { store.send(.onAppear) }
        }
    }
}
