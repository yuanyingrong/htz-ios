import UIKit
import SwiftUI
import ComposableArchitecture

@objc(HomeBridgeViewController)
class HomeBridgeViewController: UIViewController {
    
    private let store = Store(initialState: HomeFeature.State()) {
        HomeFeature()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSwiftUI()
    }
    
    private func setupSwiftUI() {
        let homeView = HomeView(store: store)
        let hostingController = UIHostingController(rootView: homeView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        
        // Match the legacy appearance if needed
        self.navigationItem.title = "Huáng Tíng Chán"
    }
}
