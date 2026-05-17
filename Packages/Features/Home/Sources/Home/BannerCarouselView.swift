import SwiftUI
import NetworkKit
import DesignSystem

public struct BannerCarouselView: View {
    let banners: [Banner]
    
    public init(banners: [Banner]) {
        self.banners = banners
    }
    
    public var body: some View {
        TabView {
            ForEach(banners) { banner in
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: banner.imageUrl.flatMap(URL.init)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.htzBackground.opacity(0.3))
                            .overlay(ProgressView())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: HTZRadius.md))
                    .padding(.horizontal, HTZSpacing.md)
                    
                    if let name = banner.name {
                        Text(name)
                            .font(.htzHeadline)
                            .foregroundColor(.white)
                            .padding(HTZSpacing.sm)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: HTZRadius.sm))
                            .padding([.leading, .bottom], HTZSpacing.lg)
                    }
                }
            }
        }
        .frame(height: 200)
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

#Preview {
    BannerCarouselView(banners: [
        Banner(id: "1", name: "Banner 1", imageUrl: "https://example.com/b1.jpg"),
        Banner(id: "2", name: "Banner 2", imageUrl: "https://example.com/b2.jpg")
    ])
    .background(Color.htzBackground)
}
