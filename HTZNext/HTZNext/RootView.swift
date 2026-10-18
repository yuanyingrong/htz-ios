import Combine
import SwiftUI
import ComposableArchitecture
import Home
import DesignSystem
import PlayerFeature
import AuthFeature

struct RootView: View {
    private let authStore = Store(initialState: AuthFeature.State()) {
        AuthFeature()
    }
    private let homeStore = Store(initialState: HomeFeature.State()) {
        HomeFeature()
    }
    private let albumStore = Store(initialState: AlbumsFeature.State()) {
        AlbumsFeature()
    }
    private let profileStore = Store(initialState: ProfileFeature.State()) {
        ProfileFeature()
    }
    private let playerStore = Store(initialState: PlayerFeature.State()) {
        PlayerFeature()
    }

    @State private var selectedTab = 0
    @Shared(.hidesBottomChrome) private var hidesChrome
    @ObservedObject private var chrome = HTZChrome.shared

    private let tabs = [
        TabConfig(id: 0, title: "首页", icon: "house.fill"),
        TabConfig(id: 1, title: "专辑", icon: "square.stack.fill"),
        TabConfig(id: 2, title: "我的", icon: "person.fill"),
    ]

    var body: some View {
        WithPerceptionTracking {
            @ComposableArchitecture.Bindable var authStore = authStore
            @ComposableArchitecture.Bindable var playerStore = playerStore

            // 进入任何子功能（压栈页面）时收起底部 Tab 栏，和安卓一致；
            // 页面自己要独占底部（批量编辑栏等）时再额外收起迷你播放条。
            let inSubpage = chrome.isInSubpage || !homeStore.path.isEmpty || !albumStore.path.isEmpty || !profileStore.path.isEmpty
            let showsTabBar = !inSubpage && !hidesChrome

            if authStore.isLoggedIn {
                CustomTabView(
                    selection: $selectedTab,
                    tabs: tabs,
                    tabBarHeight: 58,
                    selectedColor: HTZColor.title,
                    showsTabBar: showsTabBar
                ) { id in
                    WithPerceptionTracking {
                        switch id {
                        case 0:
                            HomeView(store: homeStore, onShowAlbums: { selectedTab = 1 })
                        case 1:
                            AlbumTabView(store: albumStore)
                        case 2:
                            ProfileView(store: profileStore) {
                                authStore.send(.logout)
                            }
                        default:
                            Color.clear
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    // 悬浮播放条只在首页、专辑两个 Tab 的根页面显示，其余（我的、任何子页面）都不显示。
                    if playerStore.currentItem != nil, showsTabBar, selectedTab == 0 || selectedTab == 1 {
                        NowPlayingBarView(store: playerStore)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 64)
                            .transaction { $0.animation = nil }
                    }
                }
                .modifier(StudyStatsRefresh(selectedTab: selectedTab, isPlaying: playerStore.isPlaying, homeStore: homeStore))
                .fullScreenCover(isPresented: $playerStore.showFullPlayer.sending(\.showFullPlayer)) {
                    FullPlayerView(store: playerStore)
                }
                .htzToast(Binding(
                    get: { playerStore.showFullPlayer ? nil : playerStore.toast },
                    set: { playerStore.send(.toastChanged($0)) }
                ))
                .ignoresSafeArea(.keyboard)
                .environment(\.playerStore, playerStore)
                .onAppear {
                    playerStore.send(.subscribeToPlayerState)
                    #if targetEnvironment(simulator)
                    if ProcessInfo.processInfo.arguments.contains("-HTZPlaySample") {
                        let url = SampleTone.write()
                        playerStore.send(.playQueue(tracks: [
                            QueueTrack(id: "sample", sutraId: "sample", title: "测试音", audioURL: url)
                        ], startIndex: 0, startPosition: 0))
                    }
                    #endif
                }
            } else {
                LoginView(store: authStore)
            }
        }
    }
}

/// 所有 Tab 常驻内存，HomeView 的 onAppear 只触发一次；切回首页 / 暂停播放时刷新学习统计（含服务端），
/// 播放中每几秒按本机累计时长刷新（纯本地读取），否则回到首页看到的仍是启动时的旧数据。
private struct StudyStatsRefresh: ViewModifier {
    let selectedTab: Int
    let isPlaying: Bool
    let homeStore: StoreOf<HomeFeature>
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .onChange(of: selectedTab) { tab in
                if tab == 0 { homeStore.send(.refreshStudy) }
            }
            .onChange(of: isPlaying) { playing in
                if !playing, selectedTab == 0 { homeStore.send(.refreshStudy) }
            }
            .onReceive(timer) { _ in
                if selectedTab == 0, isPlaying { homeStore.send(.refreshStudyLocal) }
            }
    }
}

#Preview {
    RootView()
}

#if targetEnvironment(simulator)
private enum SampleTone {
    static func write() -> URL {
        let sampleRate = 44_100
        let seconds = 3
        let count = sampleRate * seconds
        var samples = Data(count: count * 2)
        samples.withUnsafeMutableBytes { raw in
            let ptr = raw.bindMemory(to: Int16.self)
            for index in 0..<count {
                let angle = 2 * Double.pi * 440 * Double(index) / Double(sampleRate)
                ptr[index] = Int16(sin(angle) * 8000)
            }
        }
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        data.append(uint32(UInt32(36 + samples.count)))
        data.append(contentsOf: "WAVEfmt ".utf8)
        data.append(uint32(16))
        data.append(uint16(1))
        data.append(uint16(1))
        data.append(uint32(UInt32(sampleRate)))
        data.append(uint32(UInt32(sampleRate * 2)))
        data.append(uint16(2))
        data.append(uint16(16))
        data.append(contentsOf: "data".utf8)
        data.append(uint32(UInt32(samples.count)))
        data.append(samples)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("htz-sample.wav")
        try? data.write(to: url)
        return url
    }

    private static func uint16(_ value: UInt16) -> Data {
        var value = value.littleEndian
        return Data(bytes: &value, count: 2)
    }

    private static func uint32(_ value: UInt32) -> Data {
        var value = value.littleEndian
        return Data(bytes: &value, count: 4)
    }
}
#endif
