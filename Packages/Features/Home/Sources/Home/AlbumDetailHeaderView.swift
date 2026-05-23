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
            AsyncImage(url: album.imageUrl.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: HTZRadius.md)
                    .fill(Color.htzBackground.opacity(0.3))
                    .overlay(ProgressView())
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
                
                Text("张庆祥讲师") // Legacy data has this prominently
                    .font(.htzHeadline)
                    .foregroundColor(.htzAccent)
                
                Text("Album • 2024")
                    .font(.htzCaption)
                    .foregroundColor(.htzLabel.opacity(0.6))
            }
            .opacity(max(0, 1 + (scrollOffset / 150)))
        }
        .padding(.top, 40)
        .padding(.bottom, HTZSpacing.xl)
    }
}
