import Foundation
import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature

@Reducer
public struct SearchFeature {
    @ObservableState
    public struct State: Equatable {
        public var query = ""
        public var keyword = ""
        public var hits: [SearchHit] = []
        public var matchedAlbums: [Album] = []
        public var allAlbums: [Album] = []
        public var recent: [String] = SearchHistoryStore.load()
        public var isLoading = false
        public var isLoadingMore = false
        public var hasMore = false
        public var offset = 0
        public var toast: String?

        public init() {}

        public var isSearching: Bool { !keyword.isEmpty }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case albumsLoaded([Album])
        case submit
        case useRecent(String)
        case clearRecent
        case loadMore
        case page(keyword: String, hits: [SearchHit], rawCount: Int, reset: Bool)
        case failed(keyword: String)
        case hitTapped(SearchHit)
        case toast(String?)
    }

    static let pageSize = 30

    @Dependency(\.library) var library
    @Dependency(\.playback) var playback

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.query):
                if state.query.isEmpty {
                    state.keyword = ""
                    state.hits = []
                    state.matchedAlbums = []
                }
                return .none

            case .binding:
                return .none

            case .onAppear:
                guard state.allAlbums.isEmpty else { return .none }
                return .run { send in
                    await send(.albumsLoaded((try? await library.albums()) ?? []))
                }

            case let .albumsLoaded(albums):
                state.allAlbums = albums
                if state.isSearching {
                    state.matchedAlbums = Self.match(albums, keyword: state.keyword)
                }
                return .none

            case let .useRecent(query):
                state.query = query
                return .send(.submit)

            case .clearRecent:
                SearchHistoryStore.clear()
                state.recent = []
                return .none

            case .submit:
                let keyword = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !keyword.isEmpty else { return .none }
                SearchHistoryStore.add(keyword)
                state.recent = SearchHistoryStore.load()
                state.keyword = keyword
                state.hits = []
                state.offset = 0
                state.hasMore = true
                state.isLoading = true
                state.matchedAlbums = Self.match(state.allAlbums, keyword: keyword)
                return fetch(keyword: keyword, offset: 0, reset: true)

            case .loadMore:
                guard state.hasMore, !state.isLoading, !state.isLoadingMore, state.isSearching else { return .none }
                state.isLoadingMore = true
                return fetch(keyword: state.keyword, offset: state.offset, reset: false)

            case let .page(keyword, hits, rawCount, reset):
                guard keyword == state.keyword else { return .none }
                state.isLoading = false
                state.isLoadingMore = false
                state.offset += Self.pageSize
                // The server drops hits with empty highlights, so only an empty raw page means the end.
                state.hasMore = rawCount > 0
                let explanations = hits.filter { $0.lrcType.isEmpty || $0.lrcType == "explanation" }
                state.hits = reset ? explanations : state.hits + explanations
                if state.hits.isEmpty && state.matchedAlbums.isEmpty && !state.hasMore {
                    state.toast = "没有找到相关内容"
                } else if state.hits.count < 10 && state.hasMore {
                    return .send(.loadMore)
                }
                return .none

            case let .failed(keyword):
                guard keyword == state.keyword else { return .none }
                state.isLoading = false
                state.isLoadingMore = false
                state.hasMore = false
                state.toast = "搜索失败，请检查网络"
                return .none

            case let .hitTapped(hit):
                guard let album = state.allAlbums.first(where: { $0.name == hit.sutraTitle }) else {
                    state.toast = "未找到对应专辑"
                    return .none
                }
                return .run { send in
                    let items = AlbumDetailFeature.sortedAscending((try? await library.items(album.id)) ?? [])
                    guard let index = items.firstIndex(where: { $0.title == hit.title }) else {
                        await send(.toast("未找到对应章节"))
                        return
                    }
                    let tracks = items.map { QueueTrack(item: $0, sutraId: album.id, albumName: album.name, cover: album.imageUrl) }
                    await playback.play(tracks, index, true, hit.startSeconds)
                }

            case let .toast(message):
                state.toast = message
                return .none
            }
        }
    }

    private func fetch(keyword: String, offset: Int, reset: Bool) -> Effect<Action> {
        .run { send in
            do {
                let hits = try await library.search(keyword, offset, Self.pageSize)
                await send(.page(keyword: keyword, hits: hits, rawCount: hits.count, reset: reset))
            } catch {
                await send(.failed(keyword: keyword))
            }
        }
        .cancellable(id: SearchRequest.id, cancelInFlight: reset)
    }

    static func match(_ albums: [Album], keyword: String) -> [Album] {
        albums.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
    }
}

private enum SearchRequest: Hashable { case id }

enum SearchHistoryStore {
    private static let key = "htz.search.history"

    static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    static func add(_ query: String) {
        var items = load().filter { $0 != query }
        items.insert(query, at: 0)
        UserDefaults.standard.set(Array(items.prefix(10)), forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

public struct SearchView: View {
    @Perception.Bindable var store: StoreOf<SearchFeature>

    public init(store: StoreOf<SearchFeature> = Store(initialState: SearchFeature.State()) { SearchFeature() }) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            List {
                if store.isSearching {
                    results
                } else {
                    recentSection
                }
            }
            .listStyle(.plain)
            .searchable(text: $store.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索专辑、原文、讲解")
            .onSubmit(of: .search) { store.send(.submit) }
            .overlay {
                if store.isLoading && store.hits.isEmpty { ProgressView() }
            }
            .htzPage("搜索")
            .htzToast($store.toast)
            .onAppear { store.send(.onAppear) }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        if !store.recent.isEmpty {
            Section {
                ForEach(store.recent, id: \.self) { item in
                    Button {
                        store.send(.useRecent(item))
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "clock").foregroundColor(HTZColor.hint)
                            Text(item).foregroundColor(HTZColor.title)
                        }
                        .font(.system(size: 14))
                    }
                }
            } header: {
                HStack {
                    Text("搜索历史")
                    Spacer()
                    Button("清空") { store.send(.clearRecent) }
                }
                .font(.system(size: 13))
                .foregroundColor(HTZColor.hint)
            }
        }
    }

    @ViewBuilder
    private var results: some View {
        if !store.matchedAlbums.isEmpty {
            Section("专辑") {
                ForEach(store.matchedAlbums) { album in
                    NavigationLink {
                        AlbumDetailView(store: Store(initialState: AlbumDetailFeature.State(album: album)) {
                            AlbumDetailFeature()
                        })
                    } label: {
                        HStack(spacing: 12) {
                            HTZRemoteImage(album.imageUrl, radius: 4).frame(width: 40, height: 40)
                            highlighted(album.name, size: 15, color: HTZColor.title)
                        }
                    }
                }
            }
        }
        if !store.hits.isEmpty {
            Section("讲解") {
                ForEach(store.hits) { hit in
                    Button {
                        store.send(.hitTapped(hit))
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(hit.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(HTZColor.title)
                                    .lineLimit(1)
                                Spacer()
                                Text(hit.time)
                                    .font(.system(size: 11).monospacedDigit())
                                    .foregroundColor(HTZColor.hint)
                            }
                            Text(hit.sutraTitle)
                                .font(.system(size: 11))
                                .foregroundColor(HTZColor.hint)
                            if !hit.content.isEmpty {
                                highlighted(hit.content, size: 13, color: HTZColor.secondary)
                                    .lineLimit(3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onAppear {
                        if hit.id == store.hits.last?.id { store.send(.loadMore) }
                    }
                }
                if store.isLoadingMore {
                    ProgressView().frame(maxWidth: .infinity)
                } else if !store.hasMore {
                    Text("没有更多数据了")
                        .font(.system(size: 12))
                        .foregroundColor(HTZColor.hint)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func highlighted(_ text: String, size: CGFloat, color: Color) -> Text {
        let plain = text.replacingOccurrences(of: "<em>", with: "").replacingOccurrences(of: "</em>", with: "")
        var attributed = AttributedString(plain)
        attributed.font = .system(size: size)
        attributed.foregroundColor = color
        let keyword = store.keyword
        if !keyword.isEmpty {
            var searchStart = attributed.startIndex
            while let range = attributed[searchStart...].range(of: keyword, options: .caseInsensitive) {
                attributed[range].foregroundColor = HTZColor.ctaStart
                searchStart = range.upperBound
            }
        }
        return Text(attributed)
    }
}
