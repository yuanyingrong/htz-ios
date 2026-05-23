import SwiftUI
import ComposableArchitecture
import Home
import NetworkKit

@main
struct HTZApp: App {
    init() {
        AuthManager.shared.setupTestAccount()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
