import ComposableArchitecture
import DesignSystem
import NetworkKit
import SwiftUI

@Reducer
public struct NotificationsFeature {
    @ObservableState
    public struct State: Equatable {
        public var items: [NoticeItem] = []
        public var isLoading = false
        public var selected: NoticeItem?
        public var toast: String?

        public init() {}

        public var unreadIds: [String] { items.filter { !$0.isRead }.map(\.id) }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case loaded([NoticeItem])
        case failed
        case open(NoticeItem)
        case markAllRead
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case unreadChanged(Int)
        }
    }

    @Dependency(\.library) var library

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                return .none

            case .onAppear:
                state.isLoading = state.items.isEmpty
                return .run { send in
                    do {
                        await send(.loaded(try await library.notifications()))
                    } catch {
                        await send(.failed)
                    }
                }

            case let .loaded(items):
                state.isLoading = false
                state.items = items
                return .send(.delegate(.unreadChanged(state.unreadIds.count)))

            case .failed:
                state.isLoading = false
                state.toast = "加载失败"
                return .none

            case let .open(item):
                var item = item
                let wasUnread = !item.isRead
                item.isRead = true
                if let index = state.items.firstIndex(where: { $0.id == item.id }) {
                    state.items[index].isRead = true
                }
                state.selected = item
                guard wasUnread else { return .none }
                return .merge(
                    .run { _ in await library.markNotificationsRead([item.id]) },
                    .send(.delegate(.unreadChanged(state.unreadIds.count)))
                )

            case .markAllRead:
                let ids = state.unreadIds
                guard !ids.isEmpty else {
                    state.toast = "没有未读通知"
                    return .none
                }
                for index in state.items.indices { state.items[index].isRead = true }
                state.toast = "已全部标记为已读"
                return .merge(
                    .run { _ in await library.markNotificationsRead(ids) },
                    .send(.delegate(.unreadChanged(0)))
                )
            }
        }
    }
}

struct NotificationsView: View {
    @Perception.Bindable var store: StoreOf<NotificationsFeature>

    var body: some View {
        WithPerceptionTracking {
            List {
                ForEach(store.items) { item in
                    Button {
                        store.send(.open(item))
                    } label: {
                        NoticeRow(item: item)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .overlay {
                if store.isLoading {
                    ProgressView()
                } else if store.items.isEmpty {
                    HTZEmptyView("暂无通知", icon: "bell")
                }
            }
            .refreshable { store.send(.onAppear) }
            .htzPage("系统通知")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("全部已读") { store.send(.markAllRead) }
                        .foregroundColor(HTZColor.title)
                        .disabled(store.unreadIds.isEmpty)
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { store.selected != nil },
                set: { if !$0 { store.send(.binding(.set(\.selected, nil))) } }
            )) {
                if let item = store.selected {
                    NoticeDetailView(item: item)
                }
            }
            .htzToast($store.toast)
            .onAppear { store.send(.onAppear) }
        }
    }
}

private struct NoticeRow: View {
    let item: NoticeItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(item.isRead ? Color.clear : HTZColor.danger)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title.isEmpty ? "系统通知" : item.title)
                        .font(.system(size: 15, weight: item.isRead ? .regular : .medium))
                        .foregroundColor(HTZColor.title)
                        .lineLimit(1)
                    Spacer()
                    Text(NoticeDate.short(item.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(HTZColor.hint)
                }
                Text(item.message)
                    .font(.system(size: 13))
                    .foregroundColor(HTZColor.hint)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(HTZColor.card)
        .contentShape(Rectangle())
    }
}

struct NoticeDetailView: View {
    let item: NoticeItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.title.isEmpty ? "系统通知" : item.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(HTZColor.title)
                if !item.createdAt.isEmpty {
                    Text(NoticeDate.full(item.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(HTZColor.hint)
                }
                Text(item.message)
                    .font(.system(size: 15))
                    .foregroundColor(HTZColor.secondary)
                    .lineSpacing(5)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(HTZColor.card, in: RoundedRectangle(cornerRadius: 12))
            .padding(12)
        }
        .htzPage("通知详情")
    }
}

enum NoticeDate {
    /// `created_at` arrives as epoch seconds/milliseconds or an ISO-like string.
    static func date(_ raw: String) -> Date? {
        if let value = Double(raw) {
            return Date(timeIntervalSince1970: value > 10_000_000_000 ? value / 1000 : value)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm:ss"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) { return date }
        }
        return nil
    }

    static func short(_ raw: String) -> String {
        guard let date = date(raw) else { return String(raw.prefix(10)) }
        let formatter = DateFormatter()
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "MM-dd"
        return formatter.string(from: date)
    }

    static func full(_ raw: String) -> String {
        guard let date = date(raw) else { return raw }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
