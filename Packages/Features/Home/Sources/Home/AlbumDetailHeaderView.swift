import SwiftUI
import NetworkKit
import DesignSystem

public struct AlbumDetailHeaderView: View {
    let album: Album
    let scrollOffset: CGFloat
    
    public init(album: Album, scrollOffset: CGFloat) {
        self.album = album
        self.scrollOffset = scrollOffset
    }
    
    private var scale: CGFloat {
        if scrollOffset > 0 {
            // Pulling down: Enlarge
            return 1 + (scrollOffset / 300)
        } else {
            // Scrolling up: Shrink
            return max(0.6, 1 + (scrollOffset / 400))
        }
    }
    
    private var blur: CGFloat {
        if scrollOffset < 0 {
            // Scrolling up: Blur intensity increases
            return min(15, abs(scrollOffset) / 10)
        }
        return 0
    }
    
    public var body: some View {
        VStack(spacing: HTZSpacing.lg) {
            // Hero Artwork
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
                case .failure:
                    RoundedRectangle(cornerRadius: HTZRadius.md)
                        .fill(Color.htzBackground.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.system(size: 48))
                                .foregroundColor(.htzLabel.opacity(0.4))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: HTZRadius.md))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 20)
            .scaleEffect(scale)
            .blur(radius: blur)
            
            // Metadata
            VStack(spacing: HTZSpacing.xs) {
                Text(album.name)
                    .font(.htzLargeTitle)
                    .foregroundColor(.htzLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HTZSpacing.xl)
                if album.isPaid {
                    Text(album.isPurchased ? "已购" : "付费 \(String(format: "%.0f", album.price)) 元")
                        .font(.htzCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(album.isPurchased ? Color.green : Color.orange))
                        .foregroundColor(.white)
                }
                if let description = album.description, !description.isEmpty {
                    Text(description)
                        .font(.htzCaption)
                        .foregroundColor(.htzLabel.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HTZSpacing.lg)
                }
            }
            .opacity(max(0, 1 + (scrollOffset / 150)))
        }
        .padding(.top, 40)
        .padding(.bottom, HTZSpacing.xl)
    }
}
