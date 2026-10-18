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
                    LibrarySearchBar()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            recommendations
                            if !store.recentHistories.isEmpty {
                                historyCard
                            }
                            if store.isCheckInEnabled {
                                checkInCard
                            }
                            studyCard
                        }
                        .padding(.horizontal, 12)
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
            HTZSectionHeader("推荐专辑", actionTitle: "更多", action: onShowAlbums)
                .padding(.horizontal, 4)

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
                ForEach(store.recommendations) { item in
                    Button {
                        store.send(.recommendationTapped(item))
                    } label: {
                        RecommendationBanner(title: item.name, imageUrl: item.imageUrl)
                    }
                    .buttonStyle(.plain)
                }
            } else if !store.albums.isEmpty {
                ForEach(store.albums.prefix(3)) { album in
                    Button {
                        store.send(.albumTapped(album))
                    } label: {
                        RecommendationBanner(title: album.name, imageUrl: album.imageUrl)
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
                HTZSectionHeader("收听历史", actionTitle: "更多") { store.send(.historyMoreTapped) }
                    .padding(.bottom, 4)
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
            .padding(.vertical, 14)
        }
    }

    private var checkInCard: some View {
        NavigationLink {
            CheckInPage()
        } label: {
            HTZCard {
                VStack(spacing: 12) {
                    HStack {
                        Text("打卡统计")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(HTZColor.title)
                        Spacer()
                        HStack(spacing: 2) {
                            Text("去打卡").font(.system(size: 13))
                            Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(HTZColor.statsAccent)
                    }
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
                Text("学习统计")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(HTZColor.title)
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

/// Search entry shared by the Home and Album tabs.
struct LibrarySearchBar: View {
    var body: some View {
        NavigationLink {
            SearchView()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                Text("搜索专辑、原文、讲解")
                    .font(.system(size: 14))
                Spacer()
            }
            .foregroundColor(HTZColor.hint)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(HTZColor.field, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
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

    var body: some View {
        ZStack(alignment: .leading) {
            HTZRemoteImage(imageUrl, radius: 0)
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
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(HTZColor.title)
                    .lineLimit(1)
                Text(album)
                    .font(.system(size: 12))
                    .foregroundColor(HTZColor.hint)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "play.circle")
                .font(.system(size: 20))
                .foregroundColor(HTZColor.hint)
        }
        .padding(.vertical, 6)
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
