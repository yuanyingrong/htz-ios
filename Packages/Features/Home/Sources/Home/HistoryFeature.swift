import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature
import SwiftUI

extension Array where Element == ListenHistoryItem {
    /// One entry per lesson, keeping the first (newest) record and the original order.
    var aggregatedByLesson: [ListenHistoryItem] {
        var seen = Set<String>()
        return filter { seen.insert($0.itemId).inserted }
    }
}

/// Playing a history entry queues the whole album it belongs to (starting at that lesson), so
/// next/previous and auto-advance work like they do from the album page.
enum HistoryPlayback {
    static func queue(for item: ListenHistoryItem, cover: String?, library: LibraryClient) async -> (tracks: [QueueTrack], index: Int) {
        let coverString = cover ?? MediaTime.ossURL(item.cover)?.absoluteString
        var single = QueueTrack(history: item)
        if let cover { single.imageUrl = URL(string: cover) }

        guard !item.sutraId.isEmpty,
              let fetched = try? await library.items(item.sutraId), !fetched.isEmpty else {
            return ([single], 0)
        }
        let items = AlbumDetailFeature.sortedAscending(fetched)
        guard let index = items.firstIndex(where: { $0.id == item.itemId })
                ?? items.firstIndex(where: { !item.title.isEmpty && $0.title == item.title }) else {
            return ([single], 0)
        }
        let tracks = items.map {
            QueueTrack(item: $0, sutraId: item.sutraId, albumName: item.sutraName, cover: coverString)
        }
        return (tracks, index)
    }
}

/// Where to continue an episode picked from a list that carries no progress of its own
/// (favorites, downloads): the newest listen-history entry for it, or 0.
enum ResumePosition {
    static func seconds(for itemId: String, library: LibraryClient, timeout: Duration = .seconds(2)) async -> Double {
        // Offline (the usual case for downloads) must not delay starting playback.
        await withTaskGroup(of: Double?.self) { group in
            group.addTask {
                let histories = (try? await library.histories()) ?? []
                let saved = histories.first { $0.itemId == itemId }?.lastPositionSeconds ?? 0
                return Double(max(0, saved))
            }
            group.addTask {
                try? await _Concurrency.Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first ?? 0
        }
    }
}

enum HistoryWatchID: Hashable { case id }

@Reducer
public struct HistoryFeature {
    @ObservableState
    public struct State: Equatable {
        /// Raw server records; the same lesson can appear several times.
        public var records: [ListenHistoryItem] = []
        /// One row per lesson (the most recent record wins; the server returns newest first).
        public var items: [ListenHistoryItem] {
            records.aggregatedByLesson
        }
        public var covers: [String: String] = [:]
        public var isLoading = false
        public var toast: String?
        public var isClearConfirmPresented = false

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case historyChanged
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

    private func reload() -> Effect<Action> {
        .run { send in
            do {
                await send(.loaded(try await library.histories()))
            } catch {
                await send(.failed)
            }
        }
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.isLoading = state.records.isEmpty
                return .merge(
                    reload(),
                    // Playing something while this page is open adds/moves entries: refresh on every write.
                    .run { send in
                        for await _ in NotificationCenter.default.notifications(named: .htzHistoryDidChange) {
                            await send(.historyChanged)
                        }
                    }
                    .cancellable(id: HistoryWatchID.id, cancelInFlight: true)
                )

            case .historyChanged:
                return reload()

            case let .loaded(items):
                state.isLoading = false
                state.records = items
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
                let cover = state.covers[item.sutraId]
                return .run { [library] _ in
                    let queue = await HistoryPlayback.queue(for: item, cover: cover, library: library)
                    await playback.play(queue.tracks, queue.index, true, Double(item.lastPositionSeconds))
                }

            case let .delete(item):
                // Remove every record of this lesson, otherwise an older duplicate would resurface.
                let ids = state.records.filter { $0.itemId == item.itemId }.map(\.id)
                return .run { send in
                    do {
                        for id in ids { try await library.deleteHistory(id) }
                        await send(.deleted(item.itemId))
                    } catch {
                        await send(.toast("删除失败"))
                    }
                }

            case let .deleted(itemId):
                state.records.removeAll { $0.itemId == itemId }
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
                state.records = []
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
            .htzConfirmSheet(
                isPresented: $store.isClearConfirmPresented,
                message: "要清空所有历史记录吗？"
            ) { store.send(.clearAllConfirmed) }
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
