import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature
import SwiftUI

/// 下载管理，对照安卓端 `DownloadActivity` / `DownloadedFragment` / `DownloadingFragment`。
@Reducer
public struct DownloadsFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Tab: Equatable, Hashable { case finished, active }

        public struct Confirm: Equatable {
            public var message: String
            public var ids: [String]
        }

        public var tab: Tab = .finished
        public var records: [DownloadRecord] = []
        /// 「选择」模式：专辑头与单曲前出现单选圈，底部出现「删除 / 取消」。
        public var isEditing = false
        public var selection: Set<String> = []
        /// 已展开的专辑；与安卓一致，默认全部折叠。
        public var expanded: Set<String> = []
        /// 已点删除、等待撤销窗口结束的条目：先从列表隐藏，窗口过后才真正删文件。
        public var hiddenIDs: Set<String> = []
        public var showUndo = false
        public var confirm: Confirm?
        public var isConfirmPresented = false
        public var isClearConfirmPresented = false
        public var toast: String?
        @Shared(.hidesBottomChrome) public var hidesBottomChrome = false

        public init() {}

        public var finished: [DownloadRecord] { records.filter { $0.isFinished && !hiddenIDs.contains($0.id) } }
        public var active: [DownloadRecord] { records.filter { !$0.isFinished } }

        public var albums: [AlbumGroup] {
            var order: [String] = []
            var groups: [String: [DownloadRecord]] = [:]
            for record in finished {
                let key = record.sutraId.isEmpty ? record.albumName : record.sutraId
                if groups[key] == nil { order.append(key) }
                groups[key, default: []].append(record)
            }
            return order.map { key in
                let items = (groups[key] ?? []).sorted { $0.lesson < $1.lesson }
                return AlbumGroup(id: key, name: items.first?.albumName.nilIfEmpty ?? "其他", cover: items.first?.imageURL, items: items)
            }
        }
    }

    public struct AlbumGroup: Equatable, Identifiable {
        public var id: String
        public var name: String
        public var cover: String?
        public var items: [DownloadRecord]
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case onDisappear
        case recordsUpdated([DownloadRecord])
        case play(DownloadRecord)
        case playAll
        case toggleEditing
        case cancelEditing
        case toggleSelection(String)
        case toggleGroupSelection(AlbumGroup)
        case toggleExpanded(String)
        case deleteSelected
        case requestDelete(message: String, ids: [String])
        case confirmDelete
        case undoDelete
        case commitDelete
        case pause(String)
        case resume(String)
        case cancel(String)
        case startAll
        case pauseAll
        case clearActiveConfirmed
    }

    @Dependency(\.downloads) var downloads
    @Dependency(\.library) var library
    @Dependency(\.playback) var playback
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.tab):
                state.isEditing = false
                state.selection = []
                syncChrome(&state)
                return .none

            case .binding:
                return .none

            case .onAppear:
                return .run { send in
                    for await records in downloads.updates() {
                        await send(.recordsUpdated(records))
                    }
                }
                .cancellable(id: ObservationID.records, cancelInFlight: true)

            case .onDisappear:
                state.isEditing = false
                state.selection = []
                return commitPending(&state)  // also re-syncs the bottom chrome

            case let .recordsUpdated(records):
                state.records = records
                state.selection = state.selection.intersection(records.map(\.id))
                return .none

            case let .play(record):
                guard record.isFinished else { return .none }
                // 与安卓一致：队列是点击的那首所在专辑里已下载的全部音频。
                let group = state.albums.first { $0.items.contains(record) }
                let items = group?.items ?? [record]
                let index = items.firstIndex(of: record) ?? 0
                return .run { [library] _ in
                    let position = await ResumePosition.seconds(for: record.itemId, library: library)
                    await playback.play(items.map(QueueTrack.init(download:)), index, true, position)
                }

            case .playAll:
                let items = state.albums.flatMap(\.items)
                guard !items.isEmpty else {
                    state.toast = "未选中任何条目"
                    return .none
                }
                return .run { [library] _ in
                    let position = await ResumePosition.seconds(for: items[0].itemId, library: library)
                    await playback.play(items.map(QueueTrack.init(download:)), 0, true, position)
                }

            case .toggleEditing:
                state.isEditing.toggle()
                state.selection = []
                syncChrome(&state)
                return .none

            case .cancelEditing:
                state.isEditing = false
                state.selection = []
                syncChrome(&state)
                return .none

            case let .toggleSelection(id):
                if state.selection.contains(id) {
                    state.selection.remove(id)
                } else {
                    state.selection.insert(id)
                }
                return .none

            case let .toggleGroupSelection(group):
                let ids = Set(group.items.map(\.id))
                if ids.isSubset(of: state.selection) {
                    state.selection.subtract(ids)
                } else {
                    state.selection.formUnion(ids)
                }
                return .none

            case let .toggleExpanded(id):
                if state.expanded.contains(id) {
                    state.expanded.remove(id)
                } else {
                    state.expanded.insert(id)
                }
                return .none

            case .deleteSelected:
                let ids = Array(state.selection)
                guard !ids.isEmpty else {
                    state.toast = "未选中任何条目"
                    return .none
                }
                state.isEditing = false
                state.selection = []
                return deleteWithUndo(&state, ids: ids)

            case let .requestDelete(message, ids):
                guard !ids.isEmpty else { return .none }
                state.confirm = State.Confirm(message: message, ids: ids)
                state.isConfirmPresented = true
                return .none

            case .confirmDelete:
                guard let confirm = state.confirm else { return .none }
                state.confirm = nil
                state.isConfirmPresented = false
                return deleteWithUndo(&state, ids: confirm.ids)

            case .undoDelete:
                state.hiddenIDs = []
                state.showUndo = false
                syncChrome(&state)
                return .cancel(id: ObservationID.undoTimer)

            case .commitDelete:
                return commitPending(&state)

            case let .pause(id):
                downloads.pause(id)
                return .none

            case let .resume(id):
                downloads.resume(id)
                return .none

            case let .cancel(id):
                downloads.delete([id])
                return .none

            case .startAll:
                for record in state.active where !isRunning(record.state) {
                    downloads.resume(record.id)
                }
                return .none

            case .pauseAll:
                for record in state.active where isRunning(record.state) {
                    downloads.pause(record.id)
                }
                return .none

            case .clearActiveConfirmed:
                downloads.delete(state.active.map(\.id))
                state.toast = "清除成功！"
                return .none
            }
        }
    }

    /// 编辑模式（删除 / 取消栏）和撤销提示都贴在底部，让 App 外壳暂时收起 Tab 栏和迷你播放条。
    private func syncChrome(_ state: inout State) {
        let hidden = state.isEditing || state.showUndo
        guard state.hidesBottomChrome != hidden else { return }
        state.$hidesBottomChrome.withLock { $0 = hidden }
    }

    /// 先隐藏，几秒内可撤销；窗口过后才真正删文件（同安卓的 Snackbar 撤销）。
    private func deleteWithUndo(_ state: inout State, ids: [String]) -> Effect<Action> {
        if !state.hiddenIDs.isEmpty {
            downloads.delete(Array(state.hiddenIDs))
        }
        state.hiddenIDs = Set(ids)
        state.showUndo = true
        syncChrome(&state)
        return .run { send in
            try await clock.sleep(for: .seconds(4))
            await send(.commitDelete)
        }
        .cancellable(id: ObservationID.undoTimer, cancelInFlight: true)
    }

    private func commitPending(_ state: inout State) -> Effect<Action> {
        guard !state.hiddenIDs.isEmpty else {
            state.showUndo = false
            syncChrome(&state)
            return .cancel(id: ObservationID.undoTimer)
        }
        downloads.delete(Array(state.hiddenIDs))
        state.hiddenIDs = []
        state.showUndo = false
        syncChrome(&state)
        return .cancel(id: ObservationID.undoTimer)
    }

    private func isRunning(_ state: DownloadRecord.State) -> Bool {
        switch state {
        case .queued, .downloading: return true
        default: return false
        }
    }
}

private enum ObservationID: Hashable { case records, undoTimer }

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - View

struct DownloadsView: View {
    @Perception.Bindable var store: StoreOf<DownloadsFeature>
    @Environment(\.playerStore) private var player
    @State private var confirmMessage = ""

    var body: some View {
        WithPerceptionTracking {
            // 读取放在 body 顶层，列表行里只用这两个值，避免在懒加载闭包里读 store。
            let playingId = player.currentItem?.id
            let isPlaying = player.isPlaying
            VStack(spacing: 0) {
                tabBar
                switch store.tab {
                case .finished: finishedList(playingId: playingId, isPlaying: isPlaying)
                case .active: activeList
                }
            }
            .htzPage("下载管理")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 8) {
                    if store.showUndo { undoBar }
                    if store.isEditing && store.tab == .finished { selectBar }
                }
                .animation(.easeInOut(duration: 0.2), value: store.showUndo)
            }
            .htzConfirmSheet(
                isPresented: $store.isConfirmPresented,
                message: store.confirm?.message ?? confirmMessage
            ) { store.send(.confirmDelete) }
            .onChange(of: store.confirm) { confirm in
                // Keep the text while the sheet animates out (the reducer clears `confirm` on confirm).
                if let confirm { confirmMessage = confirm.message }
            }
            .htzConfirmSheet(
                isPresented: $store.isClearConfirmPresented,
                message: "确定要清除所有下载任务吗？"
            ) { store.send(.clearActiveConfirmed) }
            .htzToast($store.toast)
            .onAppear { store.send(.onAppear) }
            .onDisappear { store.send(.onDisappear) }
        }
    }

    // MARK: Tabs

    private var tabBar: some View {
        HStack(spacing: 0) {
            tab("已下载", .finished)
            tab("下载中", .active)
        }
        .background(HTZColor.card)
    }

    private func tab(_ title: String, _ value: DownloadsFeature.State.Tab) -> some View {
        let selected = store.tab == value
        return Button {
            store.send(.binding(.set(\.tab, value)))
        } label: {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 15, weight: selected ? .semibold : .regular))
                    .foregroundColor(selected ? HTZColor.title : HTZColor.tabNormal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                Rectangle()
                    .fill(selected ? HTZColor.ctaStart : Color.clear)
                    .frame(width: 28, height: 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: 已下载

    @ViewBuilder
    private func finishedList(playingId: String?, isPlaying: Bool) -> some View {
        if store.finished.isEmpty {
            HTZEmptyView("还没有下载内容", icon: "arrow.down.circle")
            Spacer()
        } else {
            let albums = store.albums
            List {
                WithPerceptionTracking {
                    finishedHeader(total: albums.reduce(0) { $0 + $1.items.count })
                }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(HTZColor.card)
                ForEach(albums) { group in
                    let expanded = store.expanded.contains(group.id)
                    let hasPlaying = group.items.contains { $0.id == playingId }
                    WithPerceptionTracking {
                        albumRow(group, expanded: expanded, hasPlaying: hasPlaying, isPlaying: isPlaying)
                    }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(HTZColor.card)
                    if expanded {
                        ForEach(group.items) { record in
                            WithPerceptionTracking {
                                itemRow(record, current: record.id == playingId, isPlaying: isPlaying)
                            }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(HTZColor.card)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func finishedHeader(total: Int) -> some View {
        HStack(spacing: 0) {
            Button { store.send(.playAll) } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 20))
                    Text("播放全部").font(.system(size: 15))
                    Text("共\(total)首").font(.system(size: 14)).foregroundColor(HTZColor.hint)
                }
                .foregroundColor(HTZColor.title)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
            Button { store.send(.toggleEditing) } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                    Text("编辑").font(.system(size: 14))
                }
                .foregroundColor(HTZColor.title)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 55)
    }

    private func albumRow(_ group: DownloadsFeature.AlbumGroup, expanded: Bool, hasPlaying: Bool, isPlaying: Bool) -> some View {
        HStack(spacing: 12) {
            HTZRemoteImage(group.cover.flatMap(URL.init(string:)), radius: 8)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(HTZColor.title)
                    .lineLimit(1)
                Text("共\(group.items.count)首")
                    .font(.system(size: 12))
                    .foregroundColor(HTZColor.hint)
            }
            Spacer(minLength: 8)
            if store.isEditing {
                radio(Set(group.items.map(\.id)).isSubset(of: store.selection))
            } else {
                if hasPlaying { PlayingBars(isPlaying: isPlaying) }
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(HTZColor.hint)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 65)
        .contentShape(Rectangle())
        .onTapGesture {
            if store.isEditing {
                store.send(.toggleGroupSelection(group))
            } else {
                store.send(.toggleExpanded(group.id))
            }
        }
        .onLongPressGesture {
            guard !store.isEditing else { return }
            store.send(.requestDelete(
                message: "确定删除《\(group.name)》全部下载内容？删除后可重新下载。",
                ids: group.items.map(\.id)
            ))
        }
    }

    private func itemRow(_ record: DownloadRecord, current: Bool, isPlaying: Bool) -> some View {
        HStack(spacing: 8) {
            HTZRemoteImage(record.imageURL.flatMap(URL.init(string:)), radius: 4)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.system(size: 13, weight: current ? .bold : .regular))
                    .foregroundColor(current ? HTZColor.secondary : HTZColor.title)
                    .lineLimit(1)
                Text(record.albumName)
                    .font(.system(size: 11))
                    .foregroundColor(HTZColor.hint)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if store.isEditing {
                radio(store.selection.contains(record.id))
            } else {
                if current { PlayingBars(isPlaying: isPlaying) }
                Button {
                    store.send(.requestDelete(
                        message: "确定删除《\(record.title)》？删除后可重新下载。",
                        ids: [record.id]
                    ))
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(HTZColor.title)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 30)
        .padding(.trailing, 12)
        .frame(height: 50)
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(store.isEditing ? .toggleSelection(record.id) : .play(record))
        }
    }

    private func radio(_ checked: Bool) -> some View {
        Image(systemName: checked ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 20))
            .foregroundColor(checked ? HTZColor.ctaStart : HTZColor.hint)
            .frame(width: 24, height: 24)
    }

    private var selectBar: some View {
        VStack(spacing: 0) {
            HTZDivider(leading: 0)
            HStack(spacing: 0) {
                Button { store.send(.deleteSelected) } label: {
                    barLabel("trash", "删除（\(store.selection.count)）")
                }
                Button { store.send(.cancelEditing) } label: {
                    barLabel("xmark", "取消")
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 10)
        }
        .background(HTZColor.card)
    }

    private func barLabel(_ icon: String, _ text: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 18))
            Text(text).font(.system(size: 13))
        }
        .foregroundColor(HTZColor.title)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var undoBar: some View {
        HStack {
            Text("已删除")
                .font(.system(size: 14))
                .foregroundColor(.white)
            Spacer()
            Button("撤销") { store.send(.undoDelete) }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: 0xFFD54F))
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(HTZColor.title, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: 下载中

    @ViewBuilder
    private var activeList: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                toolButton("play.fill", "全部开始") { store.send(.startAll) }
                toolButton("pause.fill", "全部暂停") { store.send(.pauseAll) }
                toolButton("trash", "清空") { store.send(.binding(.set(\.isClearConfirmPresented, true))) }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(HTZColor.card)
            HTZDivider(leading: 0)
            if store.active.isEmpty {
                HTZEmptyView("没有正在下载的任务", icon: "arrow.down.circle")
                Spacer()
            } else {
                List {
                    ForEach(store.active) { record in
                        ActiveDownloadRow(record: record) {
                            switch record.state {
                            case .queued, .downloading: store.send(.pause(record.id))
                            default: store.send(.resume(record.id))
                            }
                        } onCancel: {
                            store.send(.cancel(record.id))
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(HTZColor.card)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func toolButton(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13))
                Text(title).font(.system(size: 12))
            }
            .foregroundColor(HTZColor.title)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ActiveDownloadRow: View {
    let record: DownloadRecord
    let onToggle: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            HTZRemoteImage(record.imageURL.flatMap(URL.init(string:)), radius: 5)
                .frame(width: 45, height: 45)
            VStack(alignment: .leading, spacing: 5) {
                Text(record.title)
                    .font(.system(size: 14))
                    .foregroundColor(HTZColor.title)
                    .lineLimit(1)
                HStack(spacing: 12) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: 0xE6E6E6))
                            Capsule()
                                .fill(HTZColor.orange)
                                .frame(width: proxy.size.width * CGFloat(min(max(record.progress, 0), 1)))
                        }
                    }
                    .frame(height: 4)
                    Text(status)
                        .font(.system(size: 10))
                        .foregroundColor(HTZColor.orange)
                        .frame(width: 64, alignment: .trailing)
                }
            }
            Button(action: onCancel) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(HTZColor.title)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }

    /// 与安卓一致：下载中只显示百分比，排队 / 暂停带前缀。
    private var status: String {
        let percent = "\(Int(min(max(record.progress, 0), 1) * 100))%"
        switch record.state {
        case .downloading: return percent
        case .queued: return "队列中 \(percent)"
        case .paused: return "暂停 \(percent)"
        case .failed: return "失败 \(percent)"
        case .finished: return "100%"
        }
    }
}

/// 播放中的三根跳动条（安卓 `AnimatedBarsView`）；暂停时静止。
private struct PlayingBars: View {
    let isPlaying: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: !isPlaying)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(HTZColor.orange)
                        .frame(width: 3, height: height(index, t))
                }
            }
            .frame(width: 16, height: 16, alignment: .bottom)
        }
        .padding(.trailing, 4)
    }

    private func height(_ index: Int, _ t: TimeInterval) -> CGFloat {
        guard isPlaying else { return [8, 14, 10][index] }
        let phase = t * 6 + Double(index) * 1.7
        return 4 + 12 * CGFloat((sin(phase) + 1) / 2)
    }
}
