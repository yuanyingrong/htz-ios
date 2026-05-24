import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit

public struct HomeView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<HomeFeature>
    
    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }
    
    private let gridItems = [
        GridItem(.flexible(), spacing: HTZSpacing.md),
        GridItem(.flexible(), spacing: HTZSpacing.md)
    ]
    
    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                ZStack {
                    // 1. Immersive Background
                    Group {
                        if let firstBanner = store.banners.first {
                            ImmersiveBackgroundView(imageUrl: firstBanner.imageUrl.flatMap(URL.init))
                        } else if let firstAlbum = store.albums.first {
                            ImmersiveBackgroundView(imageUrl: firstAlbum.imageUrl.flatMap(URL.init))
                        } else {
                            Color.htzBackground.ignoresSafeArea()
                        }
                    }
                    .contentTransition(.opacity)
                    .animation(.linear(duration: 0.8), value: store.banners.first?.id)
                    .allowsHitTesting(false)
                    
                    // 2. Main Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: HTZSpacing.xl) {
                            // Banners
                            if !store.banners.isEmpty {
                                BannerCarouselView(banners: store.banners)
                            }
                            
                            // Albums Section
                            VStack(alignment: .leading, spacing: HTZSpacing.md) {
                                Text("Recommended Albums")
                                    .font(.htzLargeTitle)
                                    .foregroundColor(.htzLabel)
                                    .padding(.horizontal, HTZSpacing.md)
                                
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
                                    LazyVGrid(columns: gridItems, spacing: HTZSpacing.md) {
                                        ForEach(store.albums) { album in
                                            AlbumCardView(album: album)
                                                .onTapGesture {
                                                    store.send(.albumTapped(album))
                                                }
                                        }
                                    }
                                    .padding(.horizontal, HTZSpacing.md)
                                }
                            }
                        }
                        .padding(.vertical, HTZSpacing.md)
                    }
                    .refreshable {
                        store.send(.onAppear)
                    }
                }
                .onAppear {
                    store.send(.onAppear)
                    print("[HomeView] onAppear")
                }
                .onChange(of: store.albums.count) { newValue in
                    print("[HomeView] albums loaded: \(newValue), banners: \(store.banners.count)")
                }
                .ignoresSafeArea(edges: .bottom)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            print("[HomeView] ScrollView safeArea: \(geo.safeAreaInsets)")
                        }
                    }
                )
                .navigationTitle("Huáng Tíng Chán")
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            } destination: { store in
                switch store.case {
                case let .albumDetail(store):
                    AlbumDetailView(store: store)
                }
            }
        }
    }
}
