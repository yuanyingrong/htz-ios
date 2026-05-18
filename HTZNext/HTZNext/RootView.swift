import SwiftUI
import ComposableArchitecture
import Home
import DesignSystem

struct RootView: View {
    // Shared store for the App
    private let homeStore = Store(initialState: HomeFeature.State()) {
        HomeFeature()
    }
    
    var body: some View {
        TabView {
            // Home Tab
            NavigationStack {
                HomeView(store: homeStore)
            }
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
    }
}

#Preview {
    RootView()
}
