import SwiftUI
import ComposableArchitecture
import Home
import DesignSystem
import PlayerFeature

struct RootView: View {
    private let homeStore = Store(initialState: HomeFeature.State()) {
        HomeFeature()
    }
    private let playerStore = Store(initialState: PlayerFeature.State()) {
        PlayerFeature()
    }

    @State private var selectedTab = 0

    private let tabs = [
        TabConfig(id: 0, title: "Home", icon: "house.fill"),
        TabConfig(id: 1, title: "Album", icon: "square.stack.fill"),
        TabConfig(id: 2, title: "Profile", icon: "person.fill"),
    ]

    var body: some View {
        WithPerceptionTracking {
            CustomTabView(
                selection: $selectedTab,
                tabs: tabs,
                fadeHeight: 60,
                tabBarHeight: 52,
                selectedColor: .htzAccent
            ) { id in
                Group {
                    switch id {
                    case 0:
                        HomeView(store: homeStore)
                    case 1:
                        NavigationStack {
                            Text("Album Feature Coming Soon")
                                .font(.htzLargeTitle)
                        }
                    case 2:
                        NavigationStack {
                            Text("Profile Feature Coming Soon")
                                .font(.htzLargeTitle)
                        }
                    default:
                        Color.clear
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if playerStore.currentItem != nil {
                    NowPlayingBarView(store: playerStore)
                        .padding(.horizontal, HTZSpacing.sm)
                        .padding(.bottom, 60)
                }
            }
            .ignoresSafeArea(.keyboard)
            .environment(\.playerStore, playerStore)
            .onAppear {
                playerStore.send(.subscribeToPlayerState)
            }
        }
    }
}

#Preview {
    RootView()
}
