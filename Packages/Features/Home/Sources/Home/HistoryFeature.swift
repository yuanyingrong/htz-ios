import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature
import SwiftUI

@Reducer
public struct HistoryFeature {
    @ObservableState
    public struct State: Equatable {
        public var items: [ListenHistoryItem] = []
        public var covers: [String: String] = [:]
        public var isLoading = false
        public var toast: String?
        public var isClearConfirmPresented = false

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case loaded([ListenHistoryItem])
        case coversLoaded([String: String])
        case failed
        case play(ListenHistoryItem)
        case delete(ListenHistoryItem)
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
                        await send(.loaded(try await library.histories()))
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
                let tracks = state.items.map { item in
                    var track = QueueTrack(history: item)
                    if let cover = covers[item.sutraId] { track.imageUrl = URL(string: cover) }
                    return track
                }
                let index = state.items.firstIndex(of: item) ?? 0
                return .run { _ in
                    await playback.play(tracks, index, true, Double(item.lastPositionSeconds))
                }

            case let .delete(item):
                return .run { send in
                    do {
                        try await library.deleteHistory(item.id)
                        await send(.deleted(item.id))
                    } catch {
                        await send(.toast("删除失败"))
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
                        try await library.deleteAllHistories()
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

public struct HistoryView: View {
    @Perception.Bindable var store: StoreOf<HistoryFeature>

    public init(store: StoreOf<HistoryFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            List {
                ForEach(store.items) { item in
                    Button {
                        store.send(.play(item))
                    } label: {
                        LibraryTrackRow(
                            title: item.title.isEmpty ? "未命名章节" : item.title,
                            subtitle: subtitle(item),
                            cover: CoverLookup.url(store.covers[item.sutraId], fallback: item.cover)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .swipeActions {
                        Button("删除", role: .destructive) { store.send(.delete(item)) }
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if store.isLoading {
                    ProgressView()
                } else if store.items.isEmpty {
                    HTZEmptyView("还没有播放记录", icon: "clock")
                }
            }
            .refreshable { store.send(.onAppear) }
            .htzPage("播放历史")
            .toolbar {
                if !store.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("清空") { store.send(.clearAllTapped) }
                            .foregroundColor(HTZColor.title)
                    }
                }
            }
            .confirmationDialog("确定清空全部播放历史？", isPresented: $store.isClearConfirmPresented, titleVisibility: .visible) {
                Button("清空", role: .destructive) { store.send(.clearAllConfirmed) }
            }
            .htzToast($store.toast)
            .onAppear { store.send(.onAppear) }
        }
    }

    private func subtitle(_ item: ListenHistoryItem) -> String {
        let seconds = item.lastPositionSeconds
        return seconds > 0 ? "\(item.sutraName) · 听到 \(MediaTime.clock(seconds))" : item.sutraName
    }
}

enum CoverLookup {
    static func signed(for sutraIds: Set<String>, library: LibraryClient) async -> [String: String] {
        await withTaskGroup(of: (String, String?).self) { group in
            for id in sutraIds where !id.isEmpty {
                group.addTask { (id, await library.coverURL(id)) }
            }
            var covers: [String: String] = [:]
            for await (id, url) in group {
                if let url { covers[id] = url }
            }
            return covers
        }
    }

    static func url(_ signed: String?, fallback: String) -> URL? {
        if let signed, let url = URL(string: signed) { return url }
        return MediaTime.ossURL(fallback)
    }
}

/// Shared row for history, favorites and search results.
struct LibraryTrackRow: View {
    let title: String
    let subtitle: String
    let cover: URL?
    var trailingIcon = "play.circle"

    var body: some View {
        HStack(spacing: 12) {
            HTZRemoteImage(cover, radius: 4)
                .frame(width: 45, height: 45)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(HTZColor.title)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(HTZColor.hint)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Image(systemName: trailingIcon)
                .font(.system(size: 20))
                .foregroundColor(HTZColor.hint)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(HTZColor.card)
        .contentShape(Rectangle())
    }
}
