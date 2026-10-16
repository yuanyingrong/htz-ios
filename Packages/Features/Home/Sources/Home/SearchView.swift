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
        public var query: String = ""
        public var hits: [SearchHit] = []
        public var recent: [String] = SearchHistoryStore.load()
        public var isLoading: Bool = false
        public var message: String?
        public init() {}

        public var albums: [String] {
            Array(Set(hits.map(\.sutraTitle).filter { !$0.isEmpty })).sorted()
        }
    }

    public enum Action: Equatable {
        case queryChanged(String)
        case submit
        case useRecent(String)
        case results([SearchHit])
        case failed(String)
        case clearMessage
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .queryChanged(query):
                state.query = query
                return .none
            case let .useRecent(query):
                state.query = query
                return .send(.submit)
            case .submit:
                let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return .none }
                state.isLoading = true
                state.message = nil
                SearchHistoryStore.add(query)
                state.recent = SearchHistoryStore.load()
                return .run { send in
                    do {
                        let hits = try await LibraryAPI.search(key: query)
                        await send(.results(hits))
                    } catch {
                        await send(.failed("搜索失败"))
                    }
                }
            case let .results(hits):
                state.isLoading = false
                state.hits = hits.filter { $0.lrcType.isEmpty || $0.lrcType == "explanation" }
                if state.hits.isEmpty { state.message = "没有找到相关内容" }
                return .none
            case let .failed(message):
                state.isLoading = false
                state.message = message
                return .none
            case .clearMessage:
                state.message = nil
                return .none
            }
        }
    }
}

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
}

public struct SearchView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<SearchFeature>
    @State private var albums: [Album] = []

    public init(store: StoreOf<SearchFeature> = Store(initialState: SearchFeature.State()) { SearchFeature() }) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            List {
                if store.hits.isEmpty {
                    Section("最近搜索") {
                        ForEach(store.recent, id: \.self) { item in
                            Button(item) { store.send(.useRecent(item)) }
                        }
                    }
                }
                if !store.albums.isEmpty {
                    Section("专辑") {
                        ForEach(store.albums, id: \.self) { title in
                            if let album = albums.first(where: { $0.name == title }) {
                                NavigationLink(title) {
                                    AlbumDetailView(store: Store(initialState: AlbumDetailFeature.State(album: album)) {
                                        AlbumDetailFeature()
                                    })
                                }
                            } else {
                                Text(title)
                            }
                        }
                    }
                }
                if !store.hits.isEmpty {
                    Section("章节") {
                        ForEach(store.hits) { hit in
                            Button {
                                play(hit)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(hit.title).font(.htzHeadline).foregroundColor(.htzLabel)
                                    Text(hit.sutraTitle).font(.htzCaption).foregroundColor(.htzLabel.opacity(0.6))
                                    if !hit.content.isEmpty {
                                        Text(hit.content).font(.htzCaption).lineLimit(2).foregroundColor(.htzLabel.opacity(0.6))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("搜索")
            .searchable(text: Binding(
                get: { store.query },
                set: { store.send(.queryChanged($0)) }
            ), prompt: "专辑或章节")
            .onSubmit(of: .search) { store.send(.submit) }
            .overlay {
                if store.isLoading { ProgressView() }
            }
            .alert("提示", isPresented: Binding(
                get: { store.message != nil },
                set: { if !$0 { store.send(.clearMessage) } }
            )) {
                Button("好的", role: .cancel) { store.send(.clearMessage) }
            } message: {
                Text(store.message ?? "")
            }
            .task {
                if albums.isEmpty {
                    albums = (try? await LibraryAPI.loadAlbums()) ?? []
                }
            }
        }
    }

    private func play(_ hit: SearchHit) {
        guard let album = albums.first(where: { $0.name == hit.sutraTitle }) else { return }
        Task {
            let items = (try? await homeItems(album.id)) ?? []
            guard let item = items.first(where: { $0.title == hit.title }) ?? items.first else { return }
            guard let file = try? await LibraryAPI.fileURL(sutraId: album.id, itemId: item.id),
                  let url = file.audioURL else { return }
            let tracks = items.map {
                QueueTrack(
                    id: $0.id,
                    sutraId: album.id,
                    title: $0.title ?? hit.title,
                    artist: album.name,
                    imageUrl: album.imageUrl.flatMap(URL.init),
                    audioURL: $0.id == item.id ? url : nil,
                    originalLyricURL: $0.id == item.id ? file.originalLyricURL : nil,
                    explanationLyricURL: $0.id == item.id ? file.explanationLyricURL : nil
                )
            }
            let index = items.firstIndex(where: { $0.id == item.id }) ?? 0
            PlayerRelay.shared.play(tracks: tracks, startIndex: index)
        }
    }

    private func homeItems(_ sutraId: String) async throws -> [SutraItem] {
        let manager = NetworkManager<HTZAPI>()
        let response: APIResponse<[SutraItem]> = try await manager.request(.items(sutraId: sutraId, pageIndex: 0, pageSize: 500))
            .eraseToAnyPublisher()
            .async()
        return response.data ?? []
    }
}
