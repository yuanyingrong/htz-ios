import Foundation
import ComposableArchitecture
import NetworkKit
import PlayerFeature

@Reducer(state: .equatable, action: .equatable)
public enum LibraryPath {
    case albumDetail(AlbumDetailFeature)
    case history(HistoryFeature)
}

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var recommendations: [Recommendation] = []
        public var albums: [Album] = []
        public var recentHistories: [ListenHistoryItem] = []
        public var historyCovers: [String: String] = [:]
        public var checkIn = HomeStats.checkIn(dates: [])
        public var study = HomeStats.study(durations: [:], completed: 0)
        @Shared(.checkInEnabled) public var isCheckInEnabled = false
        public var isLoading = false
        public var errorMessage: String?
        public var toast: String?
        public var path = StackState<LibraryPath.State>()

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case refresh
        case recommendationsLoaded([Recommendation])
        case albumsLoaded([Album])
        case albumsFailed
        case historiesLoaded([ListenHistoryItem], covers: [String: String])
        case statsLoaded(HomeStats.CheckIn, HomeStats.Study)
        case albumTapped(Album)
        case recommendationTapped(Recommendation)
        case playHistory(ListenHistoryItem)
        case historyMoreTapped
        case path(StackActionOf<LibraryPath>)
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
                return .merge(
                    state.albums.isEmpty ? loadLibrary(state: &state) : .none,
                    loadDashboard()
                )

            case .refresh:
                return .merge(loadLibrary(state: &state), loadDashboard())

            case let .recommendationsLoaded(items):
                state.recommendations = Array(items.prefix(3))
                return .none

            case let .albumsLoaded(albums):
                state.isLoading = false
                state.albums = albums
                return .none

            case .albumsFailed:
                state.isLoading = false
                if state.albums.isEmpty { state.errorMessage = "专辑加载失败" }
                return .none

            case let .historiesLoaded(items, covers):
                state.recentHistories = items
                state.historyCovers.merge(covers) { _, new in new }
                return .none

            case let .statsLoaded(checkIn, study):
                state.checkIn = checkIn
                state.study = study
                return .none

            case let .albumTapped(album):
                state.path.append(.albumDetail(AlbumDetailFeature.State(album: album)))
                return .none

            case let .recommendationTapped(item):
                let album = state.albums.first { $0.id == item.sutraId }
                    ?? Album(id: item.sutraId, name: item.name, imageUrl: item.imageUrl, description: item.description)
                state.path.append(.albumDetail(AlbumDetailFeature.State(album: album)))
                return .none

            case let .playHistory(item):
                var track = QueueTrack(history: item)
                if let cover = state.historyCovers[item.sutraId] { track.imageUrl = URL(string: cover) }
                return .run { [track] _ in
                    await playback.play([track], 0, true, Double(item.lastPositionSeconds))
                }

            case .historyMoreTapped:
                state.path.append(.history(HistoryFeature.State()))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    private func loadLibrary(state: inout State) -> Effect<Action> {
        state.isLoading = state.albums.isEmpty
        state.errorMessage = nil
        return .merge(
            .run { send in
                do {
                    await send(.albumsLoaded(try await library.albums()))
                } catch {
                    await send(.albumsFailed)
                }
            },
            .run { send in
                if let items = try? await library.recommendations() {
                    await send(.recommendationsLoaded(items))
                }
            }
        )
    }

    private func loadDashboard() -> Effect<Action> {
        .merge(
            .run { send in
                let recent = Array(((try? await library.histories()) ?? []).prefix(3))
                let covers = await CoverLookup.signed(for: Set(recent.map(\.sutraId)), library: library)
                await send(.historiesLoaded(recent, covers: covers))
            },
            .run { send in
                let stats = await HomeStats.load(unionid: AuthManager.shared.unionid ?? "", library: library)
                await send(.statsLoaded(stats.0, stats.1))
            }
        )
    }
}

@Reducer
public struct AlbumsFeature {
    @ObservableState
    public struct State: Equatable {
        public var albums: [Album] = []
        public var recent: ListenHistoryItem?
        public var isLoading = false
        public var errorMessage: String?
        public var path = StackState<LibraryPath.State>()

        public init() {}

        public var recentAlbum: Album? {
            guard let recent else { return nil }
            return albums.first { $0.id == recent.sutraId }
        }
    }

    public enum Action: Equatable {
        case onAppear
        case refresh
        case albumsLoaded([Album])
        case albumsFailed
        case recentLoaded(ListenHistoryItem?)
        case albumTapped(Album)
        case resumeRecent
        case historyTapped
        case path(StackActionOf<LibraryPath>)
    }

    @Dependency(\.library) var library
    @Dependency(\.playback) var playback

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return state.albums.isEmpty ? .send(.refresh) : loadRecent()

            case .refresh:
                state.isLoading = state.albums.isEmpty
                state.errorMessage = nil
                return .merge(
                    .run { send in
                        do {
                            await send(.albumsLoaded(try await library.albums()))
                        } catch {
                            await send(.albumsFailed)
                        }
                    },
                    loadRecent()
                )

            case let .albumsLoaded(albums):
                state.isLoading = false
                state.albums = albums
                return .none

            case .albumsFailed:
                state.isLoading = false
                if state.albums.isEmpty { state.errorMessage = "专辑加载失败" }
                return .none

            case let .recentLoaded(item):
                state.recent = item
                return .none

            case let .albumTapped(album):
                state.path.append(.albumDetail(AlbumDetailFeature.State(album: album)))
                return .none

            case .resumeRecent:
                guard let recent = state.recent else { return .none }
                var track = QueueTrack(history: recent)
                if let cover = state.recentAlbum?.imageUrl { track.imageUrl = URL(string: cover) }
                return .run { [track] _ in
                    await playback.play([track], 0, true, Double(recent.lastPositionSeconds))
                }

            case .historyTapped:
                state.path.append(.history(HistoryFeature.State()))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    private func loadRecent() -> Effect<Action> {
        .run { send in
            await send(.recentLoaded((try? await library.histories())?.first))
        }
    }
}
