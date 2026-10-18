import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit

public struct AlbumTabView: View {
    @Perception.Bindable var store: StoreOf<AlbumsFeature>

    public init(store: StoreOf<AlbumsFeature>) {
        self.store = store
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                VStack(spacing: 0) {
                    LibrarySearchBar { store.send(.historyTapped) }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            HTZSectionHeader("所有专辑", actionTitle: "播放历史") { store.send(.historyTapped) }

                            if let recent = store.recent, let album = store.recentAlbum {
                                RecentListenCard(album: album, itemTitle: recent.title) {
                                    store.send(.albumTapped(album))
                                } onResume: {
                                    store.send(.resumeRecent)
                                }
                            }

                            if store.isLoading && store.albums.isEmpty {
                                ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                            } else if let error = store.errorMessage, store.albums.isEmpty {
                                VStack(spacing: 12) {
                                    Text(error).foregroundColor(HTZColor.hint)
                                    Button("重试") { store.send(.refresh) }
                                        .buttonStyle(HTZPillButtonStyle())
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
                        .padding(.top, 4)
                        .padding(.bottom, 120)
                    }
                    .refreshable { store.send(.refresh) }
                }
                .background(HTZColor.page.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .onAppear { store.send(.onAppear) }
            } destination: { store in
                LibraryDestination(store: store)
            }
        }
    }
}

private struct RecentListenCard: View {
    let album: Album
    let itemTitle: String
    let onOpen: () -> Void
    let onResume: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HTZRemoteImage(album.imageUrl, radius: 6)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("最近收听")
                    .font(.system(size: 12))
                    .foregroundColor(HTZColor.hint)
                Text(album.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(HTZColor.title)
                    .lineLimit(1)
                Text(itemTitle)
                    .font(.system(size: 12))
                    .foregroundColor(HTZColor.hint)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Button("继续收听", action: onResume)
                .buttonStyle(HTZPillButtonStyle())
        }
        .padding(12)
        .background(HTZColor.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }
}

private struct AlbumGridCell: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay(HTZRemoteImage(album.imageUrl, radius: 8))
                .overlay(alignment: .topTrailing) {
                    if album.isPaid {
                        HTZBadge(album.isPurchased ? .purchased : .paid).padding(4)
                    }
                }
            Text(album.name)
                .font(.system(size: 13))
                .foregroundColor(HTZColor.title)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }
}
