import SwiftUI
import WebKit
import ComposableArchitecture
import DesignSystem
import NetworkKit

public struct HomeView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<HomeFeature>
    var onShowAlbums: () -> Void = {}

    public init(store: StoreOf<HomeFeature>, onShowAlbums: @escaping () -> Void = {}) {
        self.store = store
        self.onShowAlbums = onShowAlbums
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                VStack(spacing: 0) {
                    searchRow
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            recommendation
                            if !store.recentHistories.isEmpty {
                                historyCard
                            }
                            checkInCard
                            studyCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 140)
                    }
                    .refreshable {
                        store.send(.onAppear)
                        store.send(.loadDashboard)
                    }
                }
                .background(HomePalette.page.ignoresSafeArea())
                .navigationBarHidden(true)
                .onAppear {
                    store.send(.onAppear)
                    store.send(.loadDashboard)
                }
                .alert("提示", isPresented: Binding(
                    get: { store.notice != nil },
                    set: { if !$0 { store.send(.clearNotice) } }
                )) {
                    Button("好的", role: .cancel) { store.send(.clearNotice) }
                } message: {
                    Text(store.notice ?? "")
                }
            } destination: { store in
                switch store.case {
                case let .albumDetail(store):
                    AlbumDetailView(store: store)
                }
            }
        }
    }

    private var searchRow: some View {
        HStack(spacing: 12) {
            NavigationLink {
                SearchView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HomePalette.label)
                    Text("搜索专辑、原文、讲解")
                        .font(.system(size: 14))
                        .foregroundColor(HomePalette.label)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(HomePalette.search, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            NavigationLink {
                HomeHistoryPage { store.send(.playHistory($0)) }
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(HomePalette.title)
                    .frame(width: 32, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var recommendation: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "waveform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HomePalette.title)
                Text("推荐专辑")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HomePalette.title)
                Spacer()
                Button(action: onShowAlbums) {
                    HStack(spacing: 2) {
                        Text("更多")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(HomePalette.title)
                }
                .buttonStyle(.plain)
            }

            if store.isLoading && store.albums.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else if let error = store.errorMessage, store.albums.isEmpty {
                VStack(spacing: 12) {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    Button("重试") { store.send(.onAppear) }
                        .font(.system(size: 15, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(store.albums.prefix(3)) { album in
                        Button {
                            store.send(.albumTapped(album))
                        } label: {
                            HomeAlbumBanner(album: album)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var historyCard: some View {
        HomeCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                    Text("收听历史")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    NavigationLink {
                        HomeHistoryPage { store.send(.playHistory($0)) }
                    } label: {
                        HStack(spacing: 2) {
                            Text("更多")
                                .font(.system(size: 14))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .foregroundColor(HomePalette.title)

                ForEach(Array(store.recentHistories.enumerated()), id: \.element.id) { index, item in
                    Button {
                        store.send(.playHistory(item))
                    } label: {
                        HomeHistoryRow(
                            title: item.title.isEmpty ? "未命名章节" : item.title,
                            album: item.sutraName,
                            cover: store.historyCovers[item.sutraId].flatMap(URL.init)
                        )
                    }
                    .buttonStyle(.plain)
                    if index < store.recentHistories.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
    }

    private var checkInCard: some View {
        NavigationLink {
            HomeCheckInPage()
        } label: {
            HomeCard {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(HomePalette.title)
                        Text("打卡统计")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(HomePalette.title)
                        Spacer()
                        HStack(spacing: 2) {
                            Text("去打卡")
                                .font(.system(size: 13))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(HomePalette.accent)
                    }
                    HStack {
                        statNumber("\(store.checkIn.continuousDays)", unit: "天", caption: "连续打卡", tint: HomePalette.accent)
                        statNumber("\(store.checkIn.monthDays)", unit: "天", caption: "本月打卡", tint: HomePalette.title)
                        statNumber("\(store.checkIn.totalDays)", unit: "天", caption: "累计打卡", tint: HomePalette.title)
                    }
                    Divider()
                    HStack {
                        ForEach(store.checkIn.recent) { day in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(day.checked ? HomePalette.accent : HomePalette.track)
                                    .frame(width: 8, height: 8)
                                Text(day.label)
                                    .font(.system(size: 12))
                                    .foregroundColor(HomePalette.label)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    Text(store.checkIn.checkedInToday ? "今日已打卡，继续保持" : "今日还未打卡，点击去打卡")
                        .font(.system(size: 12))
                        .foregroundColor(HomePalette.label)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var studyCard: some View {
        HomeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 14, weight: .semibold))
                    Text("学习统计")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(HomePalette.title)

                HStack {
                    let parts = store.study.totalParts
                    statNumber(parts.0, unit: parts.1, caption: "累计学习时长", tint: HomePalette.accent)
                    Rectangle().fill(HomePalette.divider).frame(width: 1, height: 36)
                    statNumber("\(store.study.completedLessons)", unit: "课", caption: "累计完成课程", tint: HomePalette.accent)
                }
                Divider()
                HStack {
                    period("今日", store.study.todayText)
                    period("本周", store.study.weekText)
                    period("本月", store.study.monthText)
                }
                Text("近七日学习时长")
                    .font(.system(size: 12))
                    .foregroundColor(HomePalette.label)
                HStack(alignment: .bottom) {
                    let peak = max(store.study.bars.map(\.milliseconds).max() ?? 0, 3_600_000)
                    ForEach(Array(store.study.bars.enumerated()), id: \.element.id) { index, bar in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(index == store.study.bars.count - 1 ? HomePalette.accent : HomePalette.track)
                                .frame(width: 14, height: barHeight(bar.milliseconds, peak: peak))
                            Text(bar.label)
                                .font(.system(size: 12))
                                .foregroundColor(HomePalette.label)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 78, alignment: .bottom)
            }
        }
    }

    private func barHeight(_ milliseconds: Int, peak: Int) -> CGFloat {
        guard milliseconds > 0 else { return 2 }
        return max(8, 48 * CGFloat(milliseconds) / CGFloat(peak))
    }

    private func statNumber(_ value: String, unit: String, caption: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(tint)
            Text(caption)
                .font(.system(size: 12))
                .foregroundColor(HomePalette.label)
        }
        .frame(maxWidth: .infinity)
    }

    private func period(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(HomePalette.label)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(HomePalette.title)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HomeAlbumBanner: View {
    let album: Album

    var body: some View {
        ZStack(alignment: .leading) {
            AsyncImage(url: album.imageUrl.flatMap(URL.init)) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                default:
                    HomePalette.banner
                }
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .clipped()

            Text(album.name)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(HomePalette.title)
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct HomeHistoryRow: View {
    let title: String
    let album: String
    let cover: URL?

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: cover) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                default:
                    HomePalette.banner
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(HomePalette.title)
                    .lineLimit(1)
                Text(album)
                    .font(.system(size: 12))
                    .foregroundColor(HomePalette.label)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(HomePalette.play)
        }
        .padding(.vertical, 6)
    }
}

private struct HomeCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HomePalette.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct HomeHistoryPage: View {
    let onPlay: (ListenHistoryItem) -> Void
    @State private var items: [ListenHistoryItem] = []

    var body: some View {
        List(items) { item in
            Button {
                onPlay(item)
            } label: {
                HomeHistoryRow(
                    title: item.title.isEmpty ? "未命名章节" : item.title,
                    album: item.sutraName,
                    cover: item.cover.hasPrefix("http") ? URL(string: item.cover) : nil
                )
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationTitle("收听历史")
        .navigationBarHidden(false)
        .task {
            items = (try? await LibraryAPI.histories()) ?? []
        }
        .overlay {
            if items.isEmpty { Text("还没有播放记录").foregroundColor(.secondary) }
        }
    }
}

private struct HomeCheckInPage: View {
    var body: some View {
        HomeTenYearWebView(url: URL(string: "http://app.htzchina.org/tenyears/#/tenyearsHome")!, unionid: AuthManager.shared.unionid ?? "")
            .navigationTitle("每日打卡")
            .navigationBarHidden(false)
            .ignoresSafeArea(edges: .bottom)
    }
}

private struct HomeTenYearWebView: UIViewRepresentable {
    let url: URL
    let unionid: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(unionid: unionid) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let unionid: String
        init(unionid: String) { self.unionid = unionid }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let script = "localStorage.setItem('unionid', JSON.stringify('\(unionid)'));"
            webView.evaluateJavaScript(script)
        }
    }
}

private enum HomePalette {
    static let page = Color(red: 244 / 255, green: 244 / 255, blue: 244 / 255)
    static let card = Color.white
    static let title = Color(red: 77 / 255, green: 77 / 255, blue: 77 / 255)
    static let label = Color(red: 154 / 255, green: 154 / 255, blue: 154 / 255)
    static let accent = Color(red: 192 / 255, green: 138 / 255, blue: 75 / 255)
    static let track = Color(red: 237 / 255, green: 228 / 255, blue: 216 / 255)
    static let search = Color(red: 232 / 255, green: 232 / 255, blue: 232 / 255)
    static let banner = Color(red: 236 / 255, green: 225 / 255, blue: 211 / 255)
    static let play = Color(red: 34 / 255, green: 168 / 255, blue: 84 / 255)
    static let divider = Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255)
}
