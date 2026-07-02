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
            if authStore.isLoggedIn {
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
                                VStack(spacing: 20) {
                                    Text("Profile Feature Coming Soon")
                                        .font(.htzHeadline)
                                        .foregroundStyle(Color.secondary)
                                    
                                    Button(action: {
                                        authStore.send(.logout)
                                    }) {
                                        Text("退出登录")
                                            .font(.htzHeadline)
                                            .foregroundColor(.white)
                                            .frame(width: 160, height: 44)
                                            .background(Color.red)
                                            .cornerRadius(22)
                                    }
                                }
                                .navigationTitle("Profile")
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
            } else {
                LoginView(store: authStore)
            }
        }
    }
}

#Preview {
    RootView()
}
