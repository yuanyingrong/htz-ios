import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit

public struct AlbumTabView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<HomeFeature>
    @State private var recent: ListenHistoryItem?

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        NavigationLink {
                            SearchView()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(AlbumPalette.label)
                                Text("搜索专辑、原文、讲解")
                                    .font(.system(size: 14))
                                    .foregroundColor(AlbumPalette.label)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(AlbumPalette.search, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            SearchView()
                        } label: {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(AlbumPalette.title)
                                .frame(width: 32, height: 36)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("所有专辑")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(AlbumPalette.title)

                            if let recent, let album = store.albums.first(where: { $0.id == recent.sutraId }) {
                                Button {
                                    store.send(.albumTapped(album))
                                } label: {
                                    RecentListenCard(album: album, itemTitle: recent.title)
                                }
                                .buttonStyle(.plain)
                            }

                            if store.isLoading && store.albums.isEmpty {
                                ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                            } else if let error = store.errorMessage, store.albums.isEmpty {
                                VStack(spacing: 12) {
                                    Text(error).foregroundColor(.red)
                                    Button("重试") { store.send(.onAppear) }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            } else {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(store.albums) { album in
                                        Button {
                                            store.send(.albumTapped(album))
                                        } label: {
                                            AlbumGridCell(album: album)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 120)
                    }
                    .refreshable { store.send(.onAppear) }
                }
                .background(AlbumPalette.page.ignoresSafeArea())
                .navigationBarHidden(true)
                .onAppear { store.send(.onAppear) }
                .task {
                    recent = (try? await LibraryAPI.histories())?.first
                }
            } destination: { store in
                switch store.case {
                case let .albumDetail(store):
                    AlbumDetailView(store: store)
                }
            }
        }
    }
}

private struct RecentListenCard: View {
    let album: Album
    let itemTitle: String

    var body: some View {
        HStack(spacing: 12) {
            cover(album.imageUrl, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("最近收听")
                    .font(.system(size: 12))
                    .foregroundColor(AlbumPalette.label)
                Text(album.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AlbumPalette.title)
                    .lineLimit(1)
                Text(itemTitle)
                    .font(.system(size: 12))
                    .foregroundColor(AlbumPalette.label)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text("继续收听")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AlbumPalette.orange, in: Capsule())
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct AlbumGridCell: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                cover(album.imageUrl, size: nil)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                if album.isPaid {
                    Text(album.isPurchased ? "已购" : "付费")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(album.isPurchased ? Color.green.opacity(0.85) : AlbumPalette.orange, in: RoundedRectangle(cornerRadius: 3))
                        .padding(4)
                }
            }
            Text(album.name)
                .font(.system(size: 13))
                .foregroundColor(AlbumPalette.title)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private func cover(_ urlString: String?, size: CGFloat?) -> some View {
    let image = AsyncImage(url: urlString.flatMap(URL.init)) { phase in
        switch phase {
        case let .success(image):
            image.resizable().scaledToFill()
        default:
            AlbumPalette.banner
        }
    }
    return Group {
        if let size {
            image.frame(width: size, height: size).clipped().clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            image.frame(maxWidth: .infinity).clipped()
        }
    }
}

enum AlbumPalette {
    static let page = Color(red: 244 / 255, green: 244 / 255, blue: 244 / 255)
    static let title = Color(red: 77 / 255, green: 77 / 255, blue: 77 / 255)
    static let label = Color(red: 154 / 255, green: 154 / 255, blue: 154 / 255)
    static let search = Color(red: 232 / 255, green: 232 / 255, blue: 232 / 255)
    static let banner = Color(red: 236 / 255, green: 225 / 255, blue: 211 / 255)
    static let orange = Color(red: 1, green: 0.48, blue: 0.18)
}
