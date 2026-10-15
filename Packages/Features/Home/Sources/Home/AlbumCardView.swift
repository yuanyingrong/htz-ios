import SwiftUI
import NetworkKit
import DesignSystem

public struct AlbumCardView: View {
    let album: Album
    
    public init(album: Album) {
        self.album = album
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HTZSpacing.xs) {
            // Artwork
            AsyncImage(url: album.imageUrl.flatMap(URL.init)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: HTZRadius.md)
                        .fill(Color.htzBackground.opacity(0.3))
                        .overlay(ProgressView())
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case let .failure(error):
                    let _ = print("[HTZDebug] AlbumCardView image failed: album=\(album.name), url=\(album.imageUrl ?? "nil"), error=\(error)")
                    RoundedRectangle(cornerRadius: HTZRadius.md)
                        .fill(Color.htzBackground.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.system(size: 32))
                                .foregroundColor(.htzLabel.opacity(0.4))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: HTZRadius.md))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.htzHeadline)
                    .foregroundColor(.htzLabel)
                    .lineLimit(1)
                
                Text("Album") // Could be category if available
                    .font(.htzCaption)
                    .foregroundColor(.htzLabel.opacity(0.6))
            }
            .padding(.horizontal, 2)
            .padding(.top, 4)
        }
        .padding(HTZSpacing.xs)
    }
}
