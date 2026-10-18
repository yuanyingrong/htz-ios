import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature

public struct AlbumDetailView: View {
    @Perception.Bindable var store: StoreOf<AlbumDetailFeature>
    @Environment(\.playerStore) private var playerStore
    @State private var showPicker = false

    public init(store: StoreOf<AlbumDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        header
                        if !store.isSelecting {
                            actionBar
                            if let resume = store.resume {
                                resumeBar(resume)
                            }
                        }
                        episodeList
                    }
                    .padding(.bottom, store.isSelecting ? 80 : 120)
                }
                .sheet(isPresented: $showPicker) {
                    EpisodePicker(items: store.items) { id in
                        showPicker = false
                        withAnimation { proxy.scrollTo(id, anchor: .top) }
                    }
                    .presentationDetents([.medium])
                }
            }
            .safeAreaInset(edge: .bottom) {
                if store.isSelecting { selectionBar }
            }
            .htzPage(store.album.name)
            .toolbar { toolbar }
            .htzToast($store.toast)
            .confirmationDialog(
                "购买专辑",
                isPresented: $store.isPurchasePromptPresented,
                titleVisibility: .visible
            ) {
                Button("立即购买 ¥\(String(format: "%.2f", store.price))") { store.send(.openPurchasePage) }
                Button("取消", role: .cancel) {}
            } message: {
                Text("《\(store.album.name)》为付费专辑，购买后即可收听全部内容。")
            }
            .sheet(
                isPresented: Binding(
                    get: { store.purchaseURL != nil },
                    set: { if !$0 { store.send(.purchasePageClosed) } }
                )
            ) {
                if let url = store.purchaseURL {
                    NavigationStack {
                        HTZWebPage(title: "购买 - \(store.album.name)", url: url)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("完成") { store.send(.purchasePageClosed) }
                                }
                            }
                    }
                }
            }
            .onAppear { store.send(.onAppear) }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if store.isSelecting {
                Button("取消") { store.send(.cancelSelecting) }
                    .foregroundColor(HTZColor.title)
            } else {
                HStack(spacing: 16) {
                    NavigationLink {
                        SearchView()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .foregroundColor(HTZColor.title)
            }
        }
    }

    private var shareText: String {
        "黄庭禅《\(store.album.name)》\n\(store.album.description ?? "")"
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            HTZRemoteImage(store.album.imageUrl, radius: 4)
                .frame(width: 90, height: 90)
                .overlay(alignment: .topLeading) {
                    if store.purchase?.isPaid == true {
                        HTZBadge(store.needsPurchase ? .paid : .purchased).padding(4)
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(store.album.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(HTZColor.title)
                    .lineLimit(1)
                Text(store.album.description ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(HTZColor.hint)
                    .lineSpacing(3)
                    .lineLimit(3)
                if store.needsPurchase {
                    HStack {
                        Text("¥\(String(format: "%.2f", store.price))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(HTZColor.price)
                        Spacer()
                        Button("立即购买") { store.send(.purchaseTapped) }
                            .buttonStyle(HTZPillButtonStyle())
                    }
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(HTZColor.card)
    }

    private var actionBar: some View {
        HStack(spacing: 0) {
            actionButton(store.isAscending ? "arrow.up.arrow.down" : "arrow.down.arrow.up", store.isAscending ? "正序" : "倒序") {
                store.send(.toggleSort)
            }
            separator
            actionButton("list.bullet", "选集") { showPicker = true }
            separator
            actionButton("arrow.down.circle", "下载") { store.send(.startSelecting) }
        }
        .frame(height: 48)
        .background(HTZColor.card)
    }

    private var separator: some View {
        Rectangle().fill(HTZColor.divider).frame(width: 1, height: 20)
    }

    private func actionButton(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14))
            .foregroundColor(HTZColor.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func resumeBar(_ resume: ListenHistoryItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "play.circle")
                .foregroundColor(HTZColor.title)
            Text(resumeText(resume))
                .font(.system(size: 15))
                .foregroundColor(HTZColor.title)
                .lineLimit(1)
            Spacer()
            Button("续播") { store.send(.resumeTapped) }
                .buttonStyle(HTZPillButtonStyle())
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(HTZColor.card)
    }

    private func resumeText(_ resume: ListenHistoryItem) -> String {
        let seconds = resume.lastPositionSeconds
        return seconds > 0 ? "续播 \(resume.title) · \(MediaTime.clock(seconds))" : "续播 \(resume.title)"
    }

    @ViewBuilder
    private var episodeList: some View {
        if store.isLoading && store.items.isEmpty {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
        } else if let error = store.errorMessage, store.items.isEmpty {
            HTZEmptyView(error, icon: "exclamationmark.triangle")
        } else if store.items.isEmpty {
            HTZEmptyView()
        } else {
            LazyVStack(spacing: 0) {
                ForEach(store.items) { item in
                    EpisodeRow(
                        item: item,
                        cover: store.album.imageUrl,
                        progress: item.id == store.resume?.itemId ? store.resume?.lastPositionSeconds : nil,
                        isPlaying: playerStore.currentItem?.id == item.id,
                        isLocked: store.needsPurchase && !item.isTrialItem,
                        showsTrial: store.needsPurchase && item.isTrialItem,
                        download: store.downloads[item.id],
                        isFavorite: store.favorites[item.id] != nil,
                        selection: store.isSelecting ? store.selection.contains(item.id) : nil
                    )
                    .onTapGesture { store.send(.trackTapped(item)) }
                    .contextMenu {
                        Button {
                            store.send(.favoriteTapped(item))
                        } label: {
                            Label(store.favorites[item.id] != nil ? "取消收藏" : "收藏", systemImage: "heart")
                        }
                        Button {
                            store.send(.downloadTapped(item))
                        } label: {
                            Label("下载", systemImage: "arrow.down.circle")
                        }
                    }
                    .id(item.id)
                    HTZDivider(leading: 72)
                }
            }
            .background(HTZColor.card)
        }
    }

    private var selectionBar: some View {
        HStack(spacing: 16) {
            Button(store.selection.isEmpty ? "全选" : "全选/取消") { store.send(.selectAll) }
                .font(.system(size: 15))
                .foregroundColor(HTZColor.title)
            Spacer()
            Button("下载（\(store.selection.count)）") { store.send(.downloadSelected) }
                .buttonStyle(HTZPillButtonStyle())
                .disabled(store.selection.isEmpty)
                .opacity(store.selection.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(HTZColor.card.shadow(.drop(color: .black.opacity(0.08), radius: 4, y: -2)))
    }
}

private struct EpisodeRow: View {
    let item: SutraItem
    let cover: String?
    let progress: Int?
    let isPlaying: Bool
    let isLocked: Bool
    let showsTrial: Bool
    let download: DownloadRecord.State?
    let isFavorite: Bool
    let selection: Bool?

    var body: some View {
        HStack(spacing: 12) {
            if let selection {
                Image(systemName: selection ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(selection ? HTZColor.ctaStart : HTZColor.hint)
            }
            HTZRemoteImage(cover, radius: 4)
                .frame(width: 45, height: 45)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.title ?? "未命名")
                        .font(.system(size: 14))
                        .foregroundColor(isPlaying ? HTZColor.ctaStart : HTZColor.title)
                        .lineLimit(1)
                    if showsTrial { HTZBadge(.trial) }
                }
                HStack(spacing: 10) {
                    Label("\(item.playedCount ?? 0)", systemImage: "play.fill")
                    Label(MediaTime.clock(item.durationSeconds), systemImage: "clock")
                    if let remain = Self.remaining(duration: item.durationSeconds, progress: progress) {
                        Text(remain).foregroundColor(HTZColor.secondary)
                    }
                    if isFavorite {
                        Image(systemName: "heart.fill").foregroundColor(HTZColor.ctaStart)
                    }
                }
                .labelStyle(CompactLabelStyle())
                .font(.system(size: 10))
                .foregroundColor(HTZColor.hint)
            }
            Spacer(minLength: 0)
            trailing
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .contentShape(Rectangle())
        .opacity(selection != nil && (isLocked || download == .finished) ? 0.45 : 1)
    }

    @ViewBuilder
    private var trailing: some View {
        if isLocked {
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(HTZColor.hint)
        } else if case let .downloading(fraction) = download {
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 10))
                .foregroundColor(HTZColor.hint)
        } else if download == .finished {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(HTZColor.statsAccent)
        } else if isPlaying {
            Image(systemName: "waveform")
                .font(.system(size: 16))
                .foregroundColor(HTZColor.ctaStart)
        } else {
            Image(systemName: "play.circle")
                .font(.system(size: 20))
                .foregroundColor(HTZColor.hint)
        }
    }

    static func remaining(duration: Int, progress: Int?) -> String? {
        guard let progress, progress > 0, duration > 0 else { return nil }
        let left = duration - progress
        guard left > 5 else { return "已播完" }
        return "剩余\((left + 59) / 60)分钟"
    }
}

private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
            configuration.title
        }
    }
}

private struct EpisodePicker: View {
    let items: [SutraItem]
    let onPick: (String) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(groups, id: \.start) { group in
                        Button {
                            if items.indices.contains(group.start) {
                                onPick(items[group.start].id)
                            }
                        } label: {
                            Text("\(group.start + 1)-\(group.end)")
                                .font(.system(size: 14))
                                .foregroundColor(HTZColor.title)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(HTZColor.page, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("选集")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var groups: [(start: Int, end: Int)] {
        stride(from: 0, to: items.count, by: 50).map { start in
            (start, min(start + 50, items.count))
        }
    }
}
