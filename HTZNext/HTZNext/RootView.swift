import SwiftUI
import ComposableArchitecture
import Home
import DesignSystem
import PlayerFeature

struct RootView: View {
    // Shared store for the App
    private let homeStore = Store(initialState: HomeFeature.State()) {
        HomeFeature()
    }
    private let playerStore = Store(initialState: PlayerFeature.State()) {
        PlayerFeature()
    }
    
    var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                TabView {
                    // Home Tab
                    HomeView(store: homeStore)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }

                    // Album Tab (Placeholder)
                    NavigationStack {
                        Text("Album Feature Coming Soon")
                            .font(.htzLargeTitle)
                    }
                    .tabItem {
                        Label("Album", systemImage: "square.stack.fill")
                    }

                    // Profile Tab (Placeholder)
                    NavigationStack {
                        Text("Profile Feature Coming Soon")
                            .font(.htzLargeTitle)
                    }
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                }
                .accentColor(.htzAccent)
                .environment(\.playerStore, playerStore) // Provide playerStore as environment value

                // Player Bar Overlay
                if playerStore.currentItem != nil {
                    NowPlayingBarView(store: playerStore)
                        .padding(.bottom, 49) // Height of the TabBar
                }
            }
        }
        .onAppear {
            playerStore.send(.subscribeToPlayerState)
        }
    }
}

#Preview {
    RootView()
}
