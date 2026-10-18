import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit

public struct HomeView: View {
    @Perception.Bindable var store: StoreOf<HomeFeature>
    var onShowAlbums: () -> Void

    public init(store: StoreOf<HomeFeature>, onShowAlbums: @escaping () -> Void = {}) {
        self.store = store
        self.onShowAlbums = onShowAlbums
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                VStack(spacing: 0) {
                    LibrarySearchBar { store.send(.historyMoreTapped) }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            recommendations
                            if !store.recentHistories.isEmpty {
                                historyCard
                            }
                            if store.isCheckInEnabled {
                                checkInCard
                            }
                            studyCard
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 140)
                    }
                    .refreshable { store.send(.refresh) }
                }
                .background(HTZColor.page.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .onAppear { store.send(.onAppear) }
                .htzToast($store.toast)
            } destination: { store in
                LibraryDestination(store: store)
            }
        }
    }

    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeModuleHeader(
                title: "推荐专辑",
                icon: HTZImage.waveTitle.resizable().frame(width: 25, height: 20),
                actionTitle: "更多",
                actionColor: HTZColor.title,
                action: onShowAlbums
            )

            if store.isLoading && store.albums.isEmpty && store.recommendations.isEmpty {
                Text("正在加载推荐内容…")
                    .font(.system(size: 13))
                    .foregroundColor(HTZColor.hint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else if let error = store.errorMessage, store.albums.isEmpty {
                VStack(spacing: 12) {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(HTZColor.hint)
                    Button("重试") { store.send(.refresh) }
                        .buttonStyle(HTZPillButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if !store.recommendations.isEmpty {
                ForEach(Array(store.recommendations.enumerated()), id: \.element.id) { index, item in
                    Button {
                        store.send(.recommendationTapped(item))
                    } label: {
                        RecommendationBanner(title: item.name, imageUrl: item.imageUrl, index: index)
                    }
                    .buttonStyle(.plain)
                }
            } else if !store.albums.isEmpty {
                ForEach(Array(store.albums.prefix(3).enumerated()), id: \.element.id) { index, album in
                    Button {
                        store.send(.albumTapped(album))
                    } label: {
                        RecommendationBanner(title: album.name, imageUrl: nil, index: index)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("暂无推荐内容，下拉可刷新")
                    .font(.system(size: 13))
                    .foregroundColor(HTZColor.hint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            }
        }
    }

    private var historyCard: some View {
        HTZCard {
            VStack(alignment: .leading, spacing: 4) {
                HomeModuleHeader(
                    title: "收听历史",
                    icon: Image(systemName: "clock").font(.system(size: 16)).foregroundColor(HTZColor.secondary),
                    actionTitle: "更多",
                    actionColor: HTZColor.title
                ) { store.send(.historyMoreTapped) }
                ForEach(Array(store.recentHistories.enumerated()), id: \.element.id) { index, item in
                    Button {
                        store.send(.playHistory(item))
                    } label: {
                        HomeHistoryRow(
                            title: item.title.isEmpty ? "未命名章节" : item.title,
                            album: item.sutraName,
                            cover: CoverLookup.url(store.historyCovers[item.sutraId], fallback: item.cover)
                        )
                    }
                    .buttonStyle(.plain)
                    if index < store.recentHistories.count - 1 {
                        HTZDivider(leading: 56)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
        }
    }

    private var checkInCard: some View {
        NavigationLink {
            CheckInPage()
        } label: {
            HTZCard {
                VStack(spacing: 12) {
                    HomeModuleHeader(
                        title: "打卡统计",
                        icon: Image(systemName: "calendar").font(.system(size: 16)).foregroundColor(HTZColor.secondary),
                        actionTitle: "去打卡",
                        actionColor: HTZColor.statsAccent,
                        actionSize: 13
                    )
                    HStack {
                        StatNumber(value: "\(store.checkIn.continuousDays)", unit: "天", caption: "连续打卡", tint: HTZColor.statsAccent)
                        StatNumber(value: "\(store.checkIn.monthDays)", unit: "天", caption: "本月打卡", tint: HTZColor.title)
                        StatNumber(value: "\(store.checkIn.totalDays)", unit: "天", caption: "累计打卡", tint: HTZColor.title)
                    }
                    HTZDivider(leading: 0)
                    HStack {
                        ForEach(store.checkIn.recent) { day in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(day.checked ? HTZColor.statsAccent : HTZColor.statsTrack)
                                    .frame(width: 8, height: 8)
                                Text(day.label)
                                    .font(.system(size: 12))
                                    .foregroundColor(HTZColor.hint)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    Text(store.checkIn.checkedInToday ? "今日已打卡，继续保持" : "今日还未打卡，点击去打卡")
                        .font(.system(size: 12))
                        .foregroundColor(HTZColor.hint)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .buttonStyle(.plain)
    }

    private var studyCard: some View {
        HTZCard {
            VStack(alignment: .leading, spacing: 12) {
                HomeModuleHeader(
                    title: "学习统计",
                    icon: Image(systemName: "chart.bar.xaxis").font(.system(size: 16)).foregroundColor(HTZColor.secondary)
                )
                HStack {
                    let parts = store.study.totalParts
                    StatNumber(value: parts.0, unit: parts.1, caption: "累计学习时长", tint: HTZColor.statsAccent)
                    Rectangle().fill(HTZColor.divider).frame(width: 1, height: 36)
                    StatNumber(value: "\(store.study.completedLessons)", unit: "课", caption: "累计完成课程", tint: HTZColor.statsAccent)
                }
                HTZDivider(leading: 0)
                HStack {
                    period("今日", store.study.todayText)
                    period("本周", store.study.weekText)
                    period("本月", store.study.monthText)
                }
                Text("近七日学习时长")
                    .font(.system(size: 12))
                    .foregroundColor(HTZColor.hint)
                HStack(alignment: .bottom) {
                    let peak = max(store.study.bars.map(\.milliseconds).max() ?? 0, 3_600_000)
                    ForEach(Array(store.study.bars.enumerated()), id: \.element.id) { index, bar in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(index == store.study.bars.count - 1 ? HTZColor.statsAccent : HTZColor.statsTrack)
                                .frame(width: 14, height: barHeight(bar.milliseconds, peak: peak))
                            Text(bar.label)
                                .font(.system(size: 12))
                                .foregroundColor(HTZColor.hint)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 78, alignment: .bottom)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private func barHeight(_ milliseconds: Int, peak: Int) -> CGFloat {
        guard milliseconds > 0 else { return 2 }
        return max(8, 48 * CGFloat(milliseconds) / CGFloat(peak))
    }

    private func period(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(HTZColor.hint)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(HTZColor.title)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Search entry shared by the Home and Album tabs: grey search field + the calendar button that opens the listening history.
struct LibrarySearchBar: View {
    var onHistory: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            NavigationLink {
                SearchView()
            } label: {
                HStack(spacing: 15) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 16)
                    Text("搜索专辑、原文、讲解")
                        .font(.system(size: 14))
                    Spacer()
                }
                .foregroundColor(HTZColor.secondary)
                .padding(.leading, 20)
                .frame(height: 33)
                .background(HTZColor.field, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onHistory) {
                HTZImage.historyButton
                    .resizable()
                    .frame(width: 25, height: 25)
                    .frame(width: 33, height: 33)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("收听历史")
        }
        .padding(.leading, 16)
        .padding(.trailing, 14)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

/// Module title row used on the Home cards: 18 pt icon, 16 pt bold title, optional trailing action with a small chevron.
private struct HomeModuleHeader<Icon: View>: View {
    let title: String
    let icon: Icon
    var actionTitle: String?
    var actionColor: Color = HTZColor.title
    var actionSize: CGFloat = 14
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            icon
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(HTZColor.title)
            Spacer(minLength: 0)
            if let actionTitle {
                if let action {
                    Button(action: action) { trailing(actionTitle) }
                        .buttonStyle(.plain)
                } else {
                    trailing(actionTitle)
                }
            }
        }
        .frame(minHeight: 28)
    }

    private func trailing(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text).font(.system(size: actionSize))
            Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(actionColor)
        .contentShape(Rectangle())
    }
}

struct LibraryDestination: View {
    let store: StoreOf<LibraryPath>

    var body: some View {
        switch store.case {
        case let .albumDetail(store):
            AlbumDetailView(store: store)
        case let .history(store):
            HistoryView(store: store)
        }
    }
}

private struct RecommendationBanner: View {
    let title: String
    let imageUrl: String?
    let index: Int

    /// Android loads `recommendation_background_url` and falls back to the bundled painting `home_listview_bg_<n>`.
    private var background: some View {
        let fallback = HTZImage.homeBanner(index).resizable().scaledToFill()
        return Group {
            if let url = imageUrl.flatMap(URL.init(string:)), url.host != nil {
                AsyncImage(url: url) { phase in
                    if case let .success(image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            background
                .frame(height: 70)
                .frame(maxWidth: .infinity)
                .clipped()

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(HTZColor.title)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.55))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.7), lineWidth: 1))
                )
                .padding(.leading, 13)
                .padding(.trailing, 48)
        }
        .frame(height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .contentShape(Rectangle())
    }
}

private struct HomeHistoryRow: View {
    let title: String
    let album: String
    let cover: URL?

    var body: some View {
        HStack(spacing: 12) {
            HTZRemoteImage(cover, radius: 4)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(HTZColor.title)
                    .lineLimit(1)
                Text(album)
                    .font(.system(size: 12))
                    .foregroundColor(HTZColor.hint)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.white, Color(hex: 0x43C56A))
                .font(.system(size: 18))
        }
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }
}

private struct StatNumber: View {
    let value: String
    let unit: String
    let caption: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 24, weight: .bold))
                Text(unit).font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(tint)
            Text(caption)
                .font(.system(size: 12))
                .foregroundColor(HTZColor.hint)
        }
        .frame(maxWidth: .infinity)
    }
}
