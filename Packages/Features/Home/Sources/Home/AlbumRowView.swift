import SwiftUI
import NetworkKit
import DesignSystem

public struct AlbumRowView: View {
    let album: Album
    
    public init(album: Album) {
        self.album = album
    }
    
    public var body: some View {
        HStack(spacing: HTZSpacing.md) {
            AsyncImage(url: album.imageUrl.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.htzBackground.opacity(0.3))
                    .overlay(ProgressView())
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: HTZRadius.sm))
            
            VStack(alignment: .leading, spacing: HTZSpacing.xs) {
                Text(album.name)
                    .font(.htzHeadline)
                    .foregroundColor(.htzLabel)
                    .lineLimit(2)
                if album.isPaid {
                    Text(album.isPurchased ? "已购" : "付费")
                        .font(.htzCaption)
                        .foregroundColor(album.isPurchased ? .green : .orange)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.htzLabel.opacity(0.3))
        }
        .padding(.vertical, HTZSpacing.sm)
        .padding(.horizontal, HTZSpacing.md)
        .background(Color.htzBackground)
    }
}
