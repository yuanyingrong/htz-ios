import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature
import SwiftUI

@Reducer
public struct ProfileFeature {
    @Reducer(state: .equatable, action: .equatable)
    public enum Path {
        case userInfo(UserInfoFeature)
        case bindPhone(BindPhoneFeature)
        case favorites(FavoritesFeature)
        case history(HistoryFeature)
        case downloads(DownloadsFeature)
        case notifications(NotificationsFeature)
        case settings(SettingsFeature)
        case feedback(FeedbackFeature)
    }

    @ObservableState
    public struct State: Equatable {
        public var profile = UserProfile()
        public var unreadNotices = 0
        @Shared(.checkInEnabled) public var isCheckInEnabled = false
        public var path = StackState<Path.State>()
        public var didLogout = false

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case profileLoaded(UserProfile)
        case unreadLoaded(Int)
        case headerTapped
        case favoritesTapped
        case historyTapped
        case downloadsTapped
        case notificationsTapped
        case settingsTapped
        case logoutHandled
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case logout
        }
    }

    @Dependency(\.library) var library

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .run { send in
                        if let profile = try? await library.profile() {
                            await send(.profileLoaded(profile))
                        }
                    },
                    .run { send in
                        let notices = (try? await library.notifications()) ?? []
                        await send(.unreadLoaded(notices.filter { !$0.isRead }.count))
                    }
                )

            case .logoutHandled:
                state.didLogout = false
                state.profile = UserProfile()
                state.unreadNotices = 0
                return .none

            case let .profileLoaded(profile):
                state.profile = profile
                return .none

            case let .unreadLoaded(count):
                state.unreadNotices = count
                return .none

            case .headerTapped:
                state.path.append(.userInfo(UserInfoFeature.State(profile: state.profile)))
                return .none

            case .favoritesTapped:
                state.path.append(.favorites(FavoritesFeature.State()))
                return .none

            case .historyTapped:
                state.path.append(.history(HistoryFeature.State()))
                return .none

            case .downloadsTapped:
                state.path.append(.downloads(DownloadsFeature.State()))
                return .none

            case .notificationsTapped:
                state.path.append(.notifications(NotificationsFeature.State()))
                return .none

            case .settingsTapped:
                state.path.append(.settings(SettingsFeature.State()))
                return .none

            case let .path(.element(_, .userInfo(.delegate(.profileChanged(profile))))):
                state.profile = profile
                return .none

            case let .path(.element(_, .userInfo(.delegate(.bindPhone(phone))))):
                state.path.append(.bindPhone(BindPhoneFeature.State(phone: phone)))
                return .none

            case let .path(.element(_, .bindPhone(.delegate(.bound(phone))))):
                state.profile.mobile = phone
                for id in state.path.ids {
                    if case var .userInfo(info) = state.path[id: id] {
                        info.profile.mobile = phone
                        state.path[id: id] = .userInfo(info)
                    }
                }
                return .none

            case let .path(.element(_, .notifications(.delegate(.unreadChanged(count))))):
                state.unreadNotices = count
                return .none

            case .path(.element(_, .settings(.delegate(.openFeedback)))):
                state.path.append(.feedback(FeedbackFeature.State()))
                return .none

            case .path(.element(_, .settings(.delegate(.logout)))):
                state.path.removeAll()
                state.didLogout = true
                return .send(.delegate(.logout))

            case .path, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

public struct ProfileView: View {
    @Perception.Bindable var store: StoreOf<ProfileFeature>
    private let onLogout: () -> Void

    public init(store: StoreOf<ProfileFeature>, onLogout: @escaping () -> Void = {}) {
        self.store = store
        self.onLogout = onLogout
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                ScrollView {
                    VStack(spacing: 10) {
                        header
                        VStack(spacing: 0) {
                            menu("heart", "我的收藏") { store.send(.favoritesTapped) }
                            HTZDivider(leading: 52)
                            menu("clock", "播放历史") { store.send(.historyTapped) }
                            HTZDivider(leading: 52)
                            menu("arrow.down.circle", "下载管理") { store.send(.downloadsTapped) }
                            HTZDivider(leading: 52)
                            menu("bell", "系统通知", dot: store.unreadNotices > 0) { store.send(.notificationsTapped) }
                            if store.isCheckInEnabled {
                                HTZDivider(leading: 52)
                                NavigationLink {
                                    CheckInPage(profile: store.profile)
                                } label: {
                                    HTZMenuRow(icon: "calendar", title: "每日打卡")
                                }
                                .buttonStyle(.plain)
                            }
                            HTZDivider(leading: 52)
                            menu("gearshape", "系统设置") { store.send(.settingsTapped) }
                        }
                    }
                    .padding(.bottom, 120)
                }
                .background(HTZColor.page.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .onAppear { store.send(.onAppear) }
                .onChange(of: store.didLogout) { didLogout in
                    guard didLogout else { return }
                    store.send(.logoutHandled)
                    onLogout()
                }
            } destination: { store in
                switch store.case {
                case let .userInfo(store): UserInfoView(store: store)
                case let .bindPhone(store): BindPhoneView(store: store)
                case let .favorites(store): FavoritesView(store: store)
                case let .history(store): HistoryView(store: store)
                case let .downloads(store): DownloadsView(store: store)
                case let .notifications(store): NotificationsView(store: store)
                case let .settings(store): SettingsView(store: store)
                case let .feedback(store): FeedbackView(store: store)
                }
            }
        }
    }

    private var header: some View {
        Button {
            store.send(.headerTapped)
        } label: {
            HStack(spacing: 16) {
                Avatar(url: store.profile.avatar, size: 70)
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.profile.nickname.isEmpty ? "未设置昵称" : store.profile.nickname)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(HTZColor.title)
                    Text(store.profile.signature.isEmpty ? "签名" : store.profile.signature)
                        .font(.system(size: 14))
                        .foregroundColor(HTZColor.hint)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(HTZColor.hint)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
            .background(HTZColor.card)
        }
        .buttonStyle(.plain)
    }

    private func menu(_ icon: String, _ title: String, dot: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HTZMenuRow(icon: icon, title: title, showsDot: dot)
        }
        .buttonStyle(.plain)
    }
}
