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
                
                Text("Album ID: \(album.id)")
                    .font(.htzCaption)
                    .foregroundColor(.htzLabel.opacity(0.6))
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

#Preview {
    AlbumRowView(album: Album(id: "1", name: "Sample Album", imageUrl: "https://example.com/a1.jpg"))
}
