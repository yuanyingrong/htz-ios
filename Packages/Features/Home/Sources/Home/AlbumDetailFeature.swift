import Foundation
import ComposableArchitecture
import NetworkKit
import PlayerFeature

@Reducer
public struct AlbumDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var album: Album
        public var items: [SutraItem] = []
        public var isAscending = true
        public var isLoading = false
        public var errorMessage: String?
        public var toast: String?
        public var resume: ListenHistoryItem?
        /// Last listened position (seconds) per episode, from the listen history (newest entry wins).
        public var progress: [String: Int] = [:]
        public var favorites: [String: String] = [:]
        public var downloads: [String: DownloadRecord.State] = [:]
        public var purchase: AlbumPurchase?
        public var isPurchasePromptPresented = false
        public var purchaseURL: URL?
        public var isSelecting = false
        public var selection: Set<String> = []

        public init(album: Album) {
            self.album = album
            if album.isPaid {
                purchase = AlbumPurchase(isPaid: true, isPurchased: album.isPurchased, paidUrl: album.paidUrl)
            }
            // Paint chapters on the first frame when we already have a cache hit (no spinner flash).
            if let cached = LibraryAPI.cachedItems(sutraId: album.id), !cached.isEmpty {
                let sorted = AlbumDetailFeature.sortedAscending(cached)
                items = sorted
                isLoading = false
            }
        }

        public var needsPurchase: Bool {
            guard let purchase else { return false }
            return purchase.isPaid && !purchase.isPurchased
        }

        public func isLocked(_ item: SutraItem) -> Bool {
            needsPurchase && !item.isTrialItem
        }

        public var price: Double { album.priceInYuan }

        /// Seconds to start from: the saved position, unless there is none or the episode is
        /// (almost) finished — a position within the last 15s is a leftover from a cut-off stream.
        public func resumePosition(of item: SutraItem) -> Int {
            guard let saved = progress[item.id], saved > 1 else { return 0 }
            let duration = item.durationSeconds
            if duration > 0, duration - saved <= Self.finishedTolerance { return 0 }
            return saved
        }

        static let finishedTolerance = 15
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case itemsLoaded([SutraItem])
        case itemsFailed(keepExisting: Bool = false)
        case coverResolved(String)
        case resumeLoaded(ListenHistoryItem?)
        case progressLoaded([String: Int])
        case historyChanged
        case favoritesLoaded([FavoriteItem])
        case downloadsUpdated([DownloadRecord])
        case purchaseLoaded(AlbumPurchase, announce: Bool)
        case trackTapped(SutraItem)
        case resumeTapped
        case toggleSort
        case favoriteTapped(SutraItem)
        case favoriteChanged(itemId: String, serverId: String?)
        case downloadTapped(SutraItem)
        case startSelecting
        case cancelSelecting
        case toggleSelection(String)
        case selectAll
        case downloadSelected
        case purchaseTapped
        case openPurchasePage
        case purchasePageClosed
        case toast(String?)
    }

    @Dependency(\.library) var library
    @Dependency(\.playback) var playback
    @Dependency(\.downloads) var downloads

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                let sutraId = state.album.id
                state.errorMessage = nil
                // Cache-first: show stored chapters immediately, then refresh over the network.
                if state.items.isEmpty, let cached = library.cachedItems(sutraId), !cached.isEmpty {
                    let sorted = Self.sortedAscending(cached)
                    state.items = state.isAscending ? sorted : sorted.reversed()
                }
                state.isLoading = state.items.isEmpty
                let hadCachedItems = !state.items.isEmpty
                return .merge(
                    .run { send in
                        do {
                            await send(.itemsLoaded(try await library.items(sutraId)))
                        } catch {
                            await send(.itemsFailed(keepExisting: hadCachedItems))
                        }
                    },
                    .run { send in
                        if let cover = await library.coverURL(sutraId) {
                            await send(.coverResolved(cover))
                        }
                    },
                    .run { send in
                        let favorites = (try? await library.favorites()) ?? []
                        await send(.favoritesLoaded(favorites))
                    },
                    refreshPurchase(sutraId: sutraId, announce: false),
                    .run { send in
                        for await records in downloads.updates() {
                            await send(.downloadsUpdated(records))
                        }
                    }
                    .cancellable(id: DownloadsObservation.id(sutraId), cancelInFlight: true),
                    // Listening to an episode here (or elsewhere) rewrites its history: keep "剩余xx分钟" fresh.
                    .run { send in
                        for await _ in NotificationCenter.default.notifications(named: .htzHistoryDidChange) {
                            await send(.historyChanged)
                        }
                    }
                    .cancellable(id: AlbumHistoryWatch.id(sutraId), cancelInFlight: true)
                )

            case .historyChanged:
                return loadProgress(state: state)

            case let .itemsLoaded(items):
                state.isLoading = false
                let sorted = Self.sortedAscending(items)
                let next = state.isAscending ? sorted : sorted.reversed()
                // Skip no-op writes so the nav chrome does not rebuild when cache == network.
                if state.items != next {
                    state.items = next
                }
                return loadProgress(state: state)

            case let .itemsFailed(keepExisting):
                state.isLoading = false
                if keepExisting || !state.items.isEmpty {
                    state.toast = "章节刷新失败，仍显示缓存"
                } else {
                    state.errorMessage = "章节加载失败"
                }
                return .none

            case let .coverResolved(url):
                // Same cover bytes under a new signed query still force every row's image view to
                // reload if we swap the string; only replace when the album had no usable URL yet
                // or the path actually changed.
                if shouldReplaceCover(state.album.imageUrl, with: url) {
                    state.album = state.album.replacingImageUrl(url)
                }
                return .none

            case let .resumeLoaded(history):
                if state.resume != history {
                    state.resume = history
                }
                return .none

            case let .progressLoaded(progress):
                if state.progress != progress {
                    state.progress = progress
                }
                return .none

            case let .favoritesLoaded(favorites):
                let next = Dictionary(
                    favorites.map { ($0.itemId, $0.serverId) },
                    uniquingKeysWith: { first, _ in first }
                )
                if state.favorites != next {
                    state.favorites = next
                }
                return .none

            case let .downloadsUpdated(records):
                let ids = Set(state.items.map(\.id))
                let albumId = state.album.id
                let next = Dictionary(
                    records.filter { $0.sutraId == albumId || ids.contains($0.id) }.map { ($0.id, $0.state) },
                    uniquingKeysWith: { _, last in last }
                )
                if state.downloads != next {
                    state.downloads = next
                }
                return .none

            case let .purchaseLoaded(purchase, announce):
                let wasPurchased = state.purchase?.isPurchased == true
                if state.purchase != purchase {
                    state.purchase = purchase
                }
                guard announce else { return .none }
                if !wasPurchased && purchase.isPurchased {
                    state.toast = "购买成功，感谢您的支持！"
                } else if !purchase.isPurchased {
                    state.toast = "未检测到购买，如已付款请稍候刷新"
                }
                return .none

            case let .trackTapped(item):
                if state.isSelecting {
                    return .send(.toggleSelection(item.id))
                }
                if state.isLocked(item) {
                    state.isPurchasePromptPresented = true
                    return .none
                }
                // Like Android: an episode that was left midway continues from there.
                return play(state: state, itemId: item.id, position: Double(state.resumePosition(of: item)))

            case .resumeTapped:
                guard let resume = state.resume else { return .none }
                if let item = state.items.first(where: { $0.id == resume.itemId }), state.isLocked(item) {
                    state.isPurchasePromptPresented = true
                    return .none
                }
                return play(state: state, itemId: resume.itemId, position: Double(resume.lastPositionSeconds))

            case .toggleSort:
                state.isAscending.toggle()
                state.items.reverse()
                return .none

            case let .favoriteTapped(item):
                let serverId = state.favorites[item.id]
                return .run { send in
                    do {
                        if let serverId, !serverId.isEmpty {
                            try await library.deleteFavorite(serverId)
                            await send(.favoriteChanged(itemId: item.id, serverId: nil))
                        } else {
                            try await library.addFavorite(item.id)
                            let favorites = (try? await library.favorites()) ?? []
                            let hit = favorites.first { $0.itemId == item.id }
                            await send(.favoriteChanged(itemId: item.id, serverId: hit?.serverId ?? ""))
                        }
                    } catch {
                        await send(.toast("收藏操作失败"))
                    }
                }

            case let .favoriteChanged(itemId, serverId):
                state.favorites[itemId] = serverId
                state.toast = serverId == nil ? "已取消收藏" : "已加入收藏"
                return .none

            case let .downloadTapped(item):
                if state.isLocked(item) {
                    state.isPurchasePromptPresented = true
                    return .none
                }
                return download(state: state, items: [item])

            case .startSelecting:
                state.isSelecting = true
                state.selection = []
                return .none

            case .cancelSelecting:
                state.isSelecting = false
                state.selection = []
                return .none

            case let .toggleSelection(id):
                guard let item = state.items.first(where: { $0.id == id }),
                      !state.isLocked(item),
                      state.downloads[id] != .finished else { return .none }
                if state.selection.contains(id) {
                    state.selection.remove(id)
                } else {
                    state.selection.insert(id)
                }
                return .none

            case .selectAll:
                let selectable = state.items
                    .filter { !state.isLocked($0) && state.downloads[$0.id] != .finished }
                    .map(\.id)
                state.selection = state.selection.count == selectable.count ? [] : Set(selectable)
                return .none

            case .downloadSelected:
                let items = state.items.filter { state.selection.contains($0.id) }
                state.isSelecting = false
                state.selection = []
                guard !items.isEmpty else { return .none }
                return download(state: state, items: items)

            case .purchaseTapped:
                state.isPurchasePromptPresented = true
                return .none

            case .openPurchasePage:
                state.isPurchasePromptPresented = false
                guard let link = state.purchase?.paidUrl ?? state.album.paidUrl, let url = URL(string: link) else {
                    state.toast = "购买链接不可用"
                    return .none
                }
                state.purchaseURL = url
                return .none

            case .purchasePageClosed:
                state.purchaseURL = nil
                return refreshPurchase(sutraId: state.album.id, announce: true)

            case let .toast(message):
                state.toast = message
                return .none
            }
        }
    }

    private func loadProgress(state: State) -> Effect<Action> {
        let ids = Set(state.items.map(\.id))
        guard !ids.isEmpty else { return .none }
        return .run { send in
            let histories = ((try? await library.histories()) ?? []).filter { ids.contains($0.itemId) }
            var progress: [String: Int] = [:]
            for history in histories where progress[history.itemId] == nil {
                progress[history.itemId] = history.lastPositionSeconds
            }
            await send(.progressLoaded(progress))
            await send(.resumeLoaded(histories.first))
        }
    }

    private func play(state: State, itemId: String, position: Double) -> Effect<Action> {
        let album = state.album
        let tracks = state.items.map { QueueTrack(item: $0, sutraId: album.id, albumName: album.name, cover: album.imageUrl) }
        let index = tracks.firstIndex { $0.id == itemId } ?? 0
        return .run { _ in
            await playback.play(tracks, index, true, position)
        }
    }

    private func download(state: State, items: [SutraItem]) -> Effect<Action> {
        let album = state.album
        let pending = items.filter { state.downloads[$0.id] != .finished }
        guard !pending.isEmpty else { return .send(.toast("已下载")) }
        return .run { send in
            await send(.toast(pending.count == 1 ? "已加入下载列表" : "已加入下载列表（\(pending.count)集）"))
            var failed = 0
            for item in pending {
                guard let urls = try? await library.fileURL(album.id, item.id), let url = urls.audioURL else {
                    failed += 1
                    continue
                }
                downloads.download(DownloadRequest(
                    itemId: item.id,
                    title: item.title ?? album.name,
                    sutraId: album.id,
                    albumName: album.name,
                    imageURL: album.imageUrl,
                    lesson: item.lesson ?? 0,
                    remoteURL: url,
                    originalLyricURL: urls.originalLyricURL,
                    explanationLyricURL: urls.explanationLyricURL
                ))
            }
            if failed > 0 {
                await send(.toast("\(failed)集获取下载地址失败"))
            }
        }
    }

    private func refreshPurchase(sutraId: String, announce: Bool) -> Effect<Action> {
        .run { send in
            if let purchase = try? await library.purchase(sutraId) {
                await send(.purchaseLoaded(purchase, announce: announce))
            }
        }
    }

    static func sortedAscending(_ items: [SutraItem]) -> [SutraItem] {
        let hasLesson = items.contains { $0.lesson != nil }
        return items.enumerated().sorted { lhs, rhs in
            let left = hasLesson ? (lhs.element.lesson ?? Int.max) : titleNumber(lhs.element.title)
            let right = hasLesson ? (rhs.element.lesson ?? Int.max) : titleNumber(rhs.element.title)
            if left == right { return lhs.offset < rhs.offset }
            return left < right
        }.map(\.element)
    }

    private static func titleNumber(_ title: String?) -> Int {
        guard let title else { return Int.max }
        let digits = title.prefix { $0.isNumber }
        return Int(digits) ?? Int.max
    }
}

/// Prefer keeping the already-displayed cover when the new signed URL only differs by query.
private func shouldReplaceCover(_ current: String?, with next: String) -> Bool {
    guard let current, !current.isEmpty, let currentURL = URL(string: current), let nextURL = URL(string: next) else {
        return true
    }
    if current == next { return false }
    return currentURL.host != nextURL.host || currentURL.path != nextURL.path
}

private enum DownloadsObservation: Hashable {
    case id(String)
}

private enum AlbumHistoryWatch: Hashable {
    case id(String)
}
