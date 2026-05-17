import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit

public struct HomeView: View {
    let store: StoreOf<HomeFeature>
    
    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(alignment: .leading, spacing: HTZSpacing.xl) {
                    // Banners
                    if !store.banners.isEmpty {
                        BannerCarouselView(banners: store.banners)
                    }
                    
                    // Albums Header
                    VStack(alignment: .leading, spacing: HTZSpacing.sm) {
                        Text("Recommended Albums")
                            .font(.htzLargeTitle)
                            .foregroundColor(.htzLabel)
                            .padding(.horizontal, HTZSpacing.md)
                        
                        // Albums List
                        if store.isLoading && store.albums.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, HTZSpacing.xxl)
                        } else if let error = store.errorMessage {
                            VStack(spacing: HTZSpacing.md) {
                                Text(error)
                                    .font(.htzBody)
                                    .foregroundColor(.red)
                                Button("Retry") {
                                    store.send(.onAppear)
                                }
                                .font(.htzHeadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, HTZSpacing.xxl)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(store.albums) { album in
                                    AlbumRowView(album: album)
                                    Divider()
                                        .padding(.leading, 80 + HTZSpacing.md * 2)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, HTZSpacing.md)
            }
            .background(Color.htzBackground)
            .onAppear {
                store.send(.onAppear)
            }
            .navigationTitle("Huáng Tíng Chán")
        }
    }
}

#Preview {
    HomeView(store: Store(initialState: HomeFeature.State()) {
        HomeFeature()
    } withDependencies: {
        $0.homeClient = HomeClient(
            getBanners: { [Banner(id: "1", name: "Banner 1", imageUrl: "")] },
            getAlbums: { [Album(id: "a1", name: "Album 1", imageUrl: "")] }
        )
    })
}
