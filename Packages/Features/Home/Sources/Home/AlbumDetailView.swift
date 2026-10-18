import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature

public struct AlbumDetailView: View {
    @Perception.Bindable var store: StoreOf<AlbumDetailFeature>
    @Environment(\.playerStore) private var playerStore
    @State private var showPicker = false
    @State private var showSearch = false
    @Shared(.hidesBottomChrome) private var hidesChrome

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
            // Keep chrome tint stable; system default flashes toolbar icons gray while
            // onAppear fans out items/purchase/favorites/downloads updates.
            .tint(HTZColor.title)
            .toolbar { toolbar }
            .navigationDestination(isPresented: $showSearch) {
                SearchView(albumName: store.album.name)
            }
            .htzToast($store.toast)
            .htzCenterDialog(isPresented: $store.isPurchasePromptPresented) { [name = store.album.name, price = store.price, showTip = showsThirdPartyTip] in
                PurchasePromptDialog(
                    albumName: name,
                    price: price,
                    showsThirdPartyTip: showTip,
                    onPurchase: { store.send(.openPurchasePage) },
                    onCancel: { store.send(.binding(.set(\.isPurchasePromptPresented, false))) }
                )
            }
            .onChange(of: store.purchaseURL) { url in
                if let host = url?.host { UserDefaults.standard.set(true, forKey: Self.visitedKey(host)) }
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
            .task(id: store.album.id) {
                // `.task` cancels if the user pops quickly; start loads immediately so cache-miss
                // albums are not delayed. Nav jitter is addressed by stable tab pages + UIKit title.
                store.send(.onAppear)
            }
            // 多选时底部有「下载」操作栏，收起迷你播放条避免盖住它。
            .onChange(of: store.isSelecting) { selecting in
                $hidesChrome.withLock { $0 = selecting }
            }
            .onDisappear { $hidesChrome.withLock { $0 = false } }
        }
    }

    /// The purchase page is a third-party site with its own login. Only the first visit per host needs
    /// the hint (same rule as Android's `ThirdPartyPurchaseTip`, minus the cookie check).
    private var showsThirdPartyTip: Bool {
        let link = store.purchase?.paidUrl ?? store.album.paidUrl
        guard let link, let host = URL(string: link)?.host else { return true }
        return !UserDefaults.standard.bool(forKey: Self.visitedKey(host))
    }

    private static func visitedKey(_ host: String) -> String { "third_party_purchase_visited_\(host)" }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        // Separate ToolbarItems — a single HStack of NavigationLink/ShareLink re-lays out
        // the principal title on every store update and briefly paints the icons gray.
        if store.isSelecting {
            ToolbarItem(placement: .topBarTrailing) {
                Button("取消") { store.send(.cancelSelecting) }
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
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
                    // Prefer album flags so the badge does not pop in after purchase API returns.
                    if store.album.isPaid || store.purchase?.isPaid == true {
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
        .transaction { $0.animation = nil }
    }

    private var actionBar: some View {
        HStack(spacing: 0) {
            actionButton(HTZImage.sort(ascending: store.isAscending), "排序") {
                store.send(.toggleSort)
            }
            separator
            actionButton(HTZImage.menu, "选集") { showPicker = true }
            separator
            actionButton(HTZImage.download, "下载") { store.send(.startSelecting) }
        }
        .frame(height: 48)
        .background(HTZColor.card)
        .transaction { $0.animation = nil }
    }

    private var separator: some View {
        Rectangle().fill(HTZColor.divider).frame(width: 1, height: 20)
    }

    private func actionButton(_ icon: Image, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                icon.resizable().scaledToFit().frame(width: 18, height: 18)
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
        .contentShape(Rectangle())
        .onTapGesture { store.send(.resumeTapped) }
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
                        progress: store.progress[item.id],
                        isCurrent: playerStore.currentItem?.id == item.id,
                        isPlaying: playerStore.currentItem?.id == item.id && playerStore.isPlaying,
                        isLocked: store.needsPurchase && !item.isTrialItem,
                        showsTrial: store.needsPurchase && item.isTrialItem,
                        download: store.downloads[item.id],
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
    /// This episode is the one loaded in the player (playing or paused).
    let isCurrent: Bool
    /// …and it is actually producing sound right now (drives the bar animation).
    let isPlaying: Bool
    let isLocked: Bool
    let showsTrial: Bool
    let download: DownloadRecord.State?
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
                        .font(.system(size: 14, weight: isCurrent ? .bold : .regular))
                        .foregroundColor(isCurrent ? HTZColor.secondary : Color(hex: 0x6B6B6B))
                        .lineLimit(1)
                }
                HStack(spacing: 10) {
                    Label { Text("\(item.playedCount ?? 0)") } icon: { HTZImage.playCount.resizable().scaledToFit().frame(width: 10, height: 10) }
                    Label { Text(MediaTime.clock(item.durationSeconds)) } icon: { HTZImage.time.resizable().scaledToFit().frame(width: 10, height: 10) }
                    if let remain = Self.remaining(duration: item.durationSeconds, progress: progress) {
                        Text(remain).foregroundColor(HTZColor.secondary)
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

    /// Right-hand cluster, same order as Android: animated bars, download state, trial badge.
    private var trailing: some View {
        HStack(spacing: 10) {
            if isCurrent {
                HTZAnimatedBars(isAnimating: isPlaying)
                    .frame(width: 30, height: 30)
                    .padding(.bottom, 5)
            }
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(HTZColor.hint)
            } else if case let .downloading(fraction) = download {
                ProgressView().scaleEffect(0.7).frame(width: 18, height: 18)
                Text("\(Int(fraction * 100))%")
                    .font(.system(size: 10))
                    .foregroundColor(HTZColor.hint)
            } else if download == .finished {
                HTZImage.downloaded.resizable().scaledToFit().frame(width: 18, height: 18)
            }
            if showsTrial { HTZBadge(.trial) }
        }
        .padding(.trailing, 10)
    }

    static func remaining(duration: Int, progress: Int?) -> String? {
        // Same as Android: only for a started, unfinished episode (within 5s of the end counts as done).
        guard let progress, progress > 0, duration > 0 else { return nil }
        let left = duration - progress
        guard left > 5 else { return nil }
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

// MARK: - 付费内容弹窗

/// Android `dialog_purchase`: title, divider, album name, price, hint, optional third-party login tip.
private struct PurchasePromptDialog: View {
    let albumName: String
    let price: Double
    let showsThirdPartyTip: Bool
    let onPurchase: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("付费内容")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: 0x333333))
            Rectangle()
                .fill(Color(hex: 0xEEEEEE))
                .frame(height: 1)
                .padding(.vertical, 15)
            Text(albumName)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0x666666))
                .multilineTextAlignment(.center)
            Text(verbatim: String(format: "¥%.2f", price))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(HTZColor.price)
                .padding(.top, 10)
            Text("此专辑为付费内容，购买后即可收听全部音频")
                .font(.system(size: 13))
                .foregroundColor(HTZColor.hint)
                .multilineTextAlignment(.center)
                .padding(.top, 15)
            if showsThirdPartyTip {
                Text("购买页面由第三方平台提供，首次购买需在该页面单独登录一次（与本应用账号相互独立），之后再来无需重复登录。购买完成后请返回本页面。")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0xB06B00))
                    .lineSpacing(3)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0xFFF7E6), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: 0xFFE0A3), lineWidth: 1))
                    .padding(.top, 15)
            }
            HStack(spacing: 12) {
                Button(action: onPurchase) {
                    Text("立即购买")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(HTZColor.cta, in: Capsule())
                }
                Button(action: onCancel) {
                    Text("取消")
                        .font(.system(size: 15))
                        .foregroundColor(HTZColor.title)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: 0xEDEDED), in: Capsule())
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
        .padding(20)
        .background(HTZColor.page, in: RoundedRectangle(cornerRadius: 12))
    }
}
