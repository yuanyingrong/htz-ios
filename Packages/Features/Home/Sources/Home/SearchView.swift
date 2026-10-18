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
        /// Raw (unfiltered) lyric hits loaded so far.
        public var hits: [SearchHit] = []
        public var matchedAlbums: [Album] = []
        public var allAlbums: [Album] = []
        public var recent: [String] = SearchHistoryStore.load()
        public var isLoading = false
        public var isLoadingMore = false
        public var hasMore = false
        public var offset = 0
        public var autoFillPages = 0
        /// Album name chosen in the filter bar; empty = all albums.
        public var filterAlbum = ""
        public var toast: String?

        public init(initialAlbum: String? = nil) {
            filterAlbum = initialAlbum ?? ""
        }

        public var isSearching: Bool { !keyword.isEmpty }

        /// Android: the server can't scope a search to one album, so filtering happens on the client.
        public var visibleHits: [SearchHit] {
            filterAlbum.isEmpty ? hits : hits.filter { $0.sutraTitle == filterAlbum }
        }

        /// Album-name matches are hidden while an album filter is active.
        public var visibleAlbums: [Album] {
            filterAlbum.isEmpty ? matchedAlbums : []
        }

        var requestSize: Int { filterAlbum.isEmpty ? SearchFeature.pageSize : SearchFeature.filterPageSize }

        /// Albums to pick from in the filter sheet: those present in the loaded hits, most hits first.
        public var filterOptions: [String] {
            var counts: [String: Int] = [:]
            var order: [String] = []
            for hit in hits where !hit.sutraTitle.isEmpty {
                if counts[hit.sutraTitle] == nil { order.append(hit.sutraTitle) }
                counts[hit.sutraTitle, default: 0] += 1
            }
            if !filterAlbum.isEmpty, counts[filterAlbum] == nil { order.append(filterAlbum) }
            return order.enumerated()
                .sorted { lhs, rhs in
                    let l = counts[lhs.element] ?? 0, r = counts[rhs.element] ?? 0
                    return l != r ? l > r : lhs.offset < rhs.offset
                }
                .map(\.element)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case onDisappear
        case albumsLoaded([Album])
        case liveSearch
        case submit
        case useRecent(String)
        case deleteRecent(String)
        case selectFilter(String)
        case loadMore
        case page(keyword: String, hits: [SearchHit], rawCount: Int, reset: Bool)
        case failed(keyword: String)
        case hitTapped(SearchHit)
        case toast(String?)
    }

    static let pageSize = 20
    static let filterPageSize = 100
    static let maxAutoFillPages = 10

    @Dependency(\.library) var library
    @Dependency(\.playback) var playback
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.query):
                let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 1 {
                    guard trimmed != state.keyword else { return .none }
                    return .run { send in
                        try await clock.sleep(for: .milliseconds(350))
                        await send(.liveSearch)
                    }
                    .cancellable(id: SearchDebounce.id, cancelInFlight: true)
                }
                // Android: fewer than 2 characters falls back to the history list.
                state.keyword = ""
                state.hits = []
                state.matchedAlbums = []
                state.isLoading = false
                state.isLoadingMore = false
                state.hasMore = false
                return .merge(.cancel(id: SearchDebounce.id), .cancel(id: SearchRequest.id))

            case .binding:
                return .none

            case .onAppear:
                guard state.allAlbums.isEmpty else { return .none }
                return .run { send in
                    await send(.albumsLoaded((try? await library.albums()) ?? []))
                }

            case .onDisappear:
                if state.isSearching {
                    SearchHistoryStore.add(state.keyword)
                    state.recent = SearchHistoryStore.load()
                }
                return .none

            case let .albumsLoaded(albums):
                state.allAlbums = albums
                if state.isSearching {
                    state.matchedAlbums = Self.match(albums, keyword: state.keyword)
                }
                return .none

            case let .useRecent(query):
                state.query = query
                return .send(.submit)

            case let .deleteRecent(item):
                SearchHistoryStore.remove(item)
                state.recent = SearchHistoryStore.load()
                return .none

            case .liveSearch:
                let keyword = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard keyword.count > 1 else { return .none }
                return startSearch(&state, keyword: keyword)

            case .submit:
                let keyword = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !keyword.isEmpty else {
                    state.toast = "未输入任何内容"
                    return .none
                }
                guard keyword.count > 1 else {
                    state.toast = "输入内容过短"
                    return .none
                }
                SearchHistoryStore.add(keyword)
                state.recent = SearchHistoryStore.load()
                return .merge(.cancel(id: SearchDebounce.id), startSearch(&state, keyword: keyword))

            case let .selectFilter(album):
                guard album != state.filterAlbum else { return .none }
                state.filterAlbum = album
                guard state.isSearching else { return .none }
                return startSearch(&state, keyword: state.keyword)

            case .loadMore:
                guard state.hasMore, !state.isLoading, !state.isLoadingMore, state.isSearching else { return .none }
                state.autoFillPages = 0
                state.isLoadingMore = true
                return fetch(keyword: state.keyword, offset: state.offset, limit: state.requestSize, reset: false)

            case let .page(keyword, hits, rawCount, reset):
                guard keyword == state.keyword else { return .none }
                state.isLoading = false
                state.isLoadingMore = false
                // `offset` is a document offset: it advances by the requested size, not by the returned count.
                state.offset += state.requestSize
                // The server drops hits with empty highlights, so only an empty raw page means the end.
                state.hasMore = rawCount > 0
                let explanations = hits.filter { $0.lrcType.isEmpty || $0.lrcType == "explanation" }
                state.hits = reset ? explanations : state.hits + explanations

                // Filtering may leave less than a screenful; keep paging (bounded) like Android.
                if state.hasMore, state.visibleHits.count < Self.pageSize, state.autoFillPages < Self.maxAutoFillPages {
                    state.autoFillPages += 1
                    state.isLoadingMore = true
                    return fetch(keyword: keyword, offset: state.offset, limit: state.requestSize, reset: false)
                }
                if state.visibleHits.isEmpty {
                    state.hasMore = false
                    if state.visibleAlbums.isEmpty { state.toast = "未查询到数据" }
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

    private func startSearch(_ state: inout State, keyword: String) -> Effect<Action> {
        state.keyword = keyword
        state.hits = []
        state.offset = 0
        state.hasMore = true
        state.autoFillPages = 0
        state.isLoading = true
        state.isLoadingMore = false
        state.matchedAlbums = Self.match(state.allAlbums, keyword: keyword)
        return fetch(keyword: keyword, offset: 0, limit: state.requestSize, reset: true)
    }

    private func fetch(keyword: String, offset: Int, limit: Int, reset: Bool) -> Effect<Action> {
        .run { send in
            do {
                let hits = try await library.search(keyword, offset, limit)
                await send(.page(keyword: keyword, hits: hits, rawCount: hits.count, reset: reset))
            } catch {
                await send(.failed(keyword: keyword))
            }
        }
        .cancellable(id: SearchRequest.id, cancelInFlight: true)
    }

    static func match(_ albums: [Album], keyword: String) -> [Album] {
        albums.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
    }
}

private enum SearchRequest: Hashable { case id }
private enum SearchDebounce: Hashable { case id }

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

    static func remove(_ query: String) {
        UserDefaults.standard.set(load().filter { $0 != query }, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Highlighting

enum SearchHighlight {
    struct Segment: Equatable {
        var text: String
        var highlighted: Bool
    }

    /// Splits `raw` into plain / highlighted runs. Server `<em>…</em>` marks win; without them the
    /// keyword itself is highlighted (album names are matched locally). Other tags are stripped.
    static func segments(_ raw: String, keyword: String) -> [Segment] {
        var result: [Segment] = []
        func append(_ text: Substring, _ highlighted: Bool) {
            let clean = String(text).replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            guard !clean.isEmpty else { return }
            result.append(Segment(text: clean, highlighted: highlighted))
        }

        var rest = raw[...]
        var foundMark = false
        while let open = rest.range(of: "<em>", options: .caseInsensitive) {
            foundMark = true
            append(rest[..<open.lowerBound], false)
            let after = rest[open.upperBound...]
            if let close = after.range(of: "</em>", options: .caseInsensitive) {
                append(after[..<close.lowerBound], true)
                rest = after[close.upperBound...]
            } else {
                append(after, true)
                rest = ""
                break
            }
        }
        if foundMark {
            append(rest, false)
            return result
        }

        guard !keyword.isEmpty else {
            append(rest, false)
            return result
        }
        while let range = rest.range(of: keyword, options: .caseInsensitive) {
            append(rest[..<range.lowerBound], false)
            append(rest[range], true)
            rest = rest[range.upperBound...]
        }
        append(rest, false)
        return result
    }

    static func text(_ raw: String, keyword: String, size: CGFloat, color: Color, weight: Font.Weight = .regular) -> Text {
        var attributed = AttributedString()
        for segment in segments(raw, keyword: keyword) {
            var piece = AttributedString(segment.text)
            piece.font = .system(size: size, weight: weight)
            piece.foregroundColor = segment.highlighted ? Color(hex: 0xFF0000) : color
            attributed += piece
        }
        return Text(attributed)
    }
}

// MARK: - Views

public struct SearchView: View {
    @Perception.Bindable var store: StoreOf<SearchFeature>
    @State private var showFilter = false

    private let hint: String

    public init(store: StoreOf<SearchFeature> = Store(initialState: SearchFeature.State()) { SearchFeature() }) {
        self.store = store
        hint = "搜索专辑、原文、讲解"
    }

    /// Entry from an album page: search is preselected to that album (Android `sutra_name`).
    public init(albumName: String) {
        store = Store(initialState: SearchFeature.State(initialAlbum: albumName)) { SearchFeature() }
        hint = "在「\(albumName)」中搜索"
    }

    public var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                if store.isSearching {
                    filterBar
                }
                List {
                    if store.isSearching {
                        results
                    } else {
                        recentRows
                    }
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.interactively)
                .overlay {
                    if store.isLoading && store.visibleHits.isEmpty && store.visibleAlbums.isEmpty {
                        ProgressView()
                    }
                }
            }
            .searchable(text: $store.query, placement: .navigationBarDrawer(displayMode: .always), prompt: hint)
            .onSubmit(of: .search) { store.send(.submit) }
            .htzPage("搜索")
            .htzToast($store.toast)
            .onAppear { store.send(.onAppear) }
            .onDisappear { store.send(.onDisappear) }
            .sheet(isPresented: $showFilter) {
                WithPerceptionTracking {
                    AlbumFilterSheet(
                        options: store.filterOptions,
                        selection: store.filterAlbum
                    ) { album in
                        store.send(.selectFilter(album))
                    }
                }
            }
        }
    }

    // MARK: Filter bar

    private var filterBar: some View {
        Button {
            showFilter = true
        } label: {
            HStack(spacing: 6) {
                Text("筛选专辑：")
                    .font(.system(size: 13))
                    .foregroundColor(HTZColor.secondary)
                Text(store.filterAlbum.isEmpty ? "全部专辑" : store.filterAlbum)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(HTZColor.title)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("▼")
                    .font(.system(size: 10))
                    .foregroundColor(HTZColor.hint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(HTZColor.card)
            .overlay(alignment: .bottom) { Rectangle().fill(HTZColor.divider).frame(height: 0.5) }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("search-album-filter")
    }

    // MARK: History

    @ViewBuilder
    private var recentRows: some View {
        ForEach(store.recent, id: \.self) { item in
            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .font(.system(size: 15))
                    .foregroundColor(HTZColor.hint)
                    .frame(width: 18)
                Text(item)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button("删除") { store.send(.deleteRecent(item)) }
                    .font(.system(size: 13))
                    .foregroundColor(.blue)
                    .buttonStyle(.borderless)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture { store.send(.useRecent(item)) }
        }
    }

    // MARK: Results

    private var results: some View {
        let keyword = store.keyword
        let covers = Dictionary(store.allAlbums.map { ($0.name, $0.imageUrl) }, uniquingKeysWith: { first, _ in first })
        return Group {
            ForEach(store.visibleAlbums) { album in
                albumRow(album, keyword: keyword)
            }
            ForEach(store.visibleHits) { hit in
                hitRow(hit, keyword: keyword, cover: covers[hit.sutraTitle] ?? nil)
                    .onAppear {
                        if hit.id == store.visibleHits.last?.id { store.send(.loadMore) }
                    }
            }
            footer
        }
    }

    private func albumRow(_ album: Album, keyword: String) -> some View {
        ZStack {
            NavigationLink {
                AlbumDetailView(store: Store(initialState: AlbumDetailFeature.State(album: album)) {
                    AlbumDetailFeature()
                })
            } label: {
                EmptyView()
            }
            .opacity(0)

            HStack(spacing: 12) {
                HTZRemoteImage(album.imageUrl, radius: 4).frame(width: 50, height: 50)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("专辑")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: 0x3F51B5))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(hex: 0xEDEFF7), in: RoundedRectangle(cornerRadius: 2))
                        SearchHighlight.text(album.name, keyword: keyword, size: 15, color: HTZColor.title)
                            .lineLimit(1)
                    }
                    if let description = album.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(HTZColor.hint)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 4)
    }

    private func hitRow(_ hit: SearchHit, keyword: String, cover: String?) -> some View {
        Button {
            store.send(.hitTapped(hit))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                HTZRemoteImage(cover, radius: 4).frame(width: 50, height: 50)
                VStack(alignment: .leading, spacing: 3) {
                    Text(hit.sutraTitle)
                        .font(.system(size: 11))
                        .foregroundColor(HTZColor.hint)
                        .lineLimit(1)
                    SearchHighlight.text(hit.title, keyword: keyword, size: 15, color: HTZColor.title)
                        .lineLimit(1)
                    if !hit.content.isEmpty {
                        SearchHighlight.text(hit.content, keyword: keyword, size: 12, color: HTZColor.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var footer: some View {
        if store.isLoadingMore {
            HStack(spacing: 8) {
                ProgressView()
                Text("正在加载...")
            }
            .font(.system(size: 14))
            .foregroundColor(HTZColor.hint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .listRowSeparator(.hidden)
        } else if !store.hasMore, !store.isLoading, !(store.visibleHits.isEmpty && store.visibleAlbums.isEmpty) {
            Text("没有更多数据了")
                .font(.system(size: 14))
                .foregroundColor(HTZColor.hint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .listRowSeparator(.hidden)
        }
    }
}

/// Bottom sheet listing albums to scope the search to (Android `dialog_list_search`).
struct AlbumFilterSheet: View {
    let options: [String]
    let selection: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var rows: [String] {
        guard !query.isEmpty else { return options }
        return options.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("选择专辑")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(HTZColor.title)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)

            TextField("搜索专辑名称…", text: $query)
                .font(.system(size: 14))
                .padding(12)
                .background(HTZColor.field.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    row("全部专辑", isSelected: selection.isEmpty) { pick("") }
                    if options.isEmpty {
                        placeholder("没有其他专辑包含该内容")
                    }
                    ForEach(rows, id: \.self) { name in
                        row(name, isSelected: name == selection) { pick(name) }
                    }
                }
            }

            Button {
                dismiss()
            } label: {
                Text("取消")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(HTZColor.cta, in: RoundedRectangle(cornerRadius: 22))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .presentationDetents([.fraction(0.7)])
        .presentationDragIndicator(.visible)
    }

    private func pick(_ name: String) {
        onSelect(name)
        dismiss()
    }

    private func row(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(HTZColor.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(isSelected ? HTZColor.field : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(HTZColor.hint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
    }
}
