import ComposableArchitecture
import XCTest
import NetworkKit
@testable import Home

@MainActor
final class HomeFeatureTests: XCTestCase {
    func testOnAppear_Success() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.homeClient = .testValue
        }
        
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        
        await store.receive(\.bannersResponse.success) {
            $0.banners = [Banner(id: "banner1")]
            $0.isLoading = true // still waiting for albums
        }
        
        await store.receive(\.albumsResponse.success) {
            $0.albums = [Album(id: "album1", name: "Album 1", imageUrl: nil)]
            $0.isLoading = false
        }
    }
    
    func testOnAppear_Failure() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.homeClient.getBanners = { throw NetworkError.unknown }
            $0.homeClient.getAlbums = { [] }
        }
        
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        
        await store.receive(\.bannersResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = "Failed to load banners"
        }
        
        await store.receive(\.albumsResponse.success) {
            $0.albums = []
            $0.isLoading = false
        }
    }
}

extension HomeClient {
    static let testValue = Self(
        getBanners: { [Banner(id: "banner1")] },
        getAlbums: { [Album(id: "album1", name: "Album 1", imageUrl: nil)] }
    )
}
