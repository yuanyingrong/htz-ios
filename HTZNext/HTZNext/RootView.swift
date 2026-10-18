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

    private let tabs = [
        TabConfig(id: 0, title: "首页", icon: "house.fill"),
        TabConfig(id: 1, title: "专辑", icon: "square.stack.fill"),
        TabConfig(id: 2, title: "我的", icon: "person.fill"),
    ]

    var body: some View {
        WithPerceptionTracking {
            @ComposableArchitecture.Bindable var authStore = authStore
            @ComposableArchitecture.Bindable var playerStore = playerStore

            if authStore.isLoggedIn {
                CustomTabView(
                    selection: $selectedTab,
                    tabs: tabs,
                    tabBarHeight: 58,
                    selectedColor: HTZColor.title
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
                    if playerStore.currentItem != nil {
                        NowPlayingBarView(store: playerStore)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 64)
                    }
                }
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
