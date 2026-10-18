import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature
import SwiftUI

@Reducer
public struct DownloadsFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Tab: Equatable, Hashable { case finished, active }

        public var tab: Tab = .finished
        public var records: [DownloadRecord] = []
        public var isEditing = false
        public var selection: Set<String> = []
        public var isClearConfirmPresented = false
        public var toast: String?

        public init() {}

        public var finished: [DownloadRecord] { records.filter(\.isFinished) }
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
                let items = groups[key] ?? []
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
        case recordsUpdated([DownloadRecord])
        case play(DownloadRecord)
        case playAlbum(AlbumGroup)
        case toggleEditing
        case toggleSelection(String)
        case deleteSelected
        case pause(String)
        case resume(String)
        case cancel(String)
        case startAll
        case pauseAll
        case clearActiveConfirmed
    }

    @Dependency(\.downloads) var downloads
    @Dependency(\.playback) var playback

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.tab):
                state.isEditing = false
                state.selection = []
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

            case let .recordsUpdated(records):
                state.records = records
                state.selection = state.selection.intersection(records.map(\.id))
                return .none

            case let .play(record):
                guard record.isFinished else { return .none }
                let group = state.albums.first { $0.items.contains(record) }
                let items = group?.items ?? [record]
                let index = items.firstIndex(of: record) ?? 0
                return .run { _ in
                    await playback.play(items.map(QueueTrack.init(download:)), index, true, 0)
                }

            case let .playAlbum(group):
                return .run { _ in
                    await playback.play(group.items.map(QueueTrack.init(download:)), 0, true, 0)
                }

            case .toggleEditing:
                state.isEditing.toggle()
                state.selection = []
                return .none

            case let .toggleSelection(id):
                if state.selection.contains(id) {
                    state.selection.remove(id)
                } else {
                    state.selection.insert(id)
                }
                return .none

            case .deleteSelected:
                let ids = Array(state.selection)
                guard !ids.isEmpty else { return .none }
                state.selection = []
                state.isEditing = false
                state.toast = "已删除\(ids.count)项"
                downloads.delete(ids)
                return .none

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
                state.toast = "已清空"
                return .none
            }
        }
    }

    private func isRunning(_ state: DownloadRecord.State) -> Bool {
        switch state {
        case .queued, .downloading: return true
        default: return false
        }
    }
}

private enum ObservationID: Hashable { case records }

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

struct DownloadsView: View {
    @Perception.Bindable var store: StoreOf<DownloadsFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                Picker("", selection: $store.tab) {
                    Text("已下载（\(store.finished.count)）").tag(DownloadsFeature.State.Tab.finished)
                    Text("下载中（\(store.active.count)）").tag(DownloadsFeature.State.Tab.active)
                }
                .pickerStyle(.segmented)
                .padding(12)
                .background(HTZColor.card)

                switch store.tab {
                case .finished: finishedList
                case .active: activeList
                }
            }
            .htzPage("下载管理")
            .toolbar {
                if store.tab == .finished && !store.finished.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(store.isEditing ? "完成" : "编辑") { store.send(.toggleEditing) }
                            .foregroundColor(HTZColor.title)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if store.isEditing {
                    Button("删除（\(store.selection.count)）") { store.send(.deleteSelected) }
                        .buttonStyle(HTZPrimaryButtonStyle())
                        .disabled(store.selection.isEmpty)
                        .opacity(store.selection.isEmpty ? 0.5 : 1)
                        .padding(16)
                        .background(HTZColor.card)
                }
            }
            .confirmationDialog("清空全部下载任务？", isPresented: $store.isClearConfirmPresented, titleVisibility: .visible) {
                Button("清空", role: .destructive) { store.send(.clearActiveConfirmed) }
            }
            .htzToast($store.toast)
            .onAppear { store.send(.onAppear) }
        }
    }

    @ViewBuilder
    private var finishedList: some View {
        if store.finished.isEmpty {
            HTZEmptyView("还没有下载内容", icon: "arrow.down.circle")
            Spacer()
        } else {
            List {
                ForEach(store.albums) { group in
                    Section {
                        ForEach(group.items) { record in
                            HStack(spacing: 12) {
                                if store.isEditing {
                                    Image(systemName: store.selection.contains(record.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(store.selection.contains(record.id) ? HTZColor.ctaStart : HTZColor.hint)
                                }
                                Text(record.title)
                                    .font(.system(size: 14))
                                    .foregroundColor(HTZColor.title)
                                    .lineLimit(1)
                                Spacer()
                                if !store.isEditing {
                                    Image(systemName: "play.circle").foregroundColor(HTZColor.hint)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.send(store.isEditing ? .toggleSelection(record.id) : .play(record))
                            }
                            .swipeActions {
                                Button("删除", role: .destructive) { store.send(.cancel(record.id)) }
                            }
                        }
                    } header: {
                        HStack(spacing: 10) {
                            HTZRemoteImage(group.cover, radius: 4).frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(HTZColor.title)
                                Text("共\(group.items.count)集")
                                    .font(.system(size: 11))
                                    .foregroundColor(HTZColor.hint)
                            }
                            Spacer()
                            if !store.isEditing {
                                Button("播放全部") { store.send(.playAlbum(group)) }
                                    .font(.system(size: 12))
                                    .foregroundColor(HTZColor.ctaStart)
                            }
                        }
                        .textCase(nil)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private var activeList: some View {
        if store.active.isEmpty {
            HTZEmptyView("没有正在下载的任务", icon: "arrow.down.circle")
            Spacer()
        } else {
            HStack(spacing: 12) {
                Button("全部开始") { store.send(.startAll) }
                Button("全部暂停") { store.send(.pauseAll) }
                Spacer()
                Button("清空") { store.send(.binding(.set(\.isClearConfirmPresented, true))) }
                    .foregroundColor(HTZColor.danger)
            }
            .font(.system(size: 14))
            .foregroundColor(HTZColor.title)
            .padding(.horizontal, 16)
            .frame(height: 44)
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
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct ActiveDownloadRow: View {
    let record: DownloadRecord
    let onToggle: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(record.title)
                    .font(.system(size: 14))
                    .foregroundColor(HTZColor.title)
                    .lineLimit(1)
                if case let .downloading(fraction) = record.state {
                    ProgressView(value: fraction).tint(HTZColor.ctaStart)
                }
                Text(status)
                    .font(.system(size: 11))
                    .foregroundColor(HTZColor.hint)
            }
            Spacer()
            Button(action: onToggle) {
                Image(systemName: isRunning ? "pause.circle" : "arrow.clockwise.circle")
                    .font(.system(size: 22))
                    .foregroundColor(HTZColor.title)
            }
            .buttonStyle(.plain)
            Button(action: onCancel) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 22))
                    .foregroundColor(HTZColor.hint)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var isRunning: Bool {
        switch record.state {
        case .queued, .downloading: return true
        default: return false
        }
    }

    private var status: String {
        switch record.state {
        case .queued: return "等待中"
        case let .downloading(fraction): return "下载中 \(Int(fraction * 100))%"
        case .paused: return "已暂停"
        case .finished: return "已完成"
        case let .failed(message): return "失败：\(message)"
        }
    }
}
