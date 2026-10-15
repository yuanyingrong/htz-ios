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
                    AsyncImage(url: banner.imageUrl.flatMap(URL.init)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.htzBackground.opacity(0.3))
                                .overlay(ProgressView())
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.htzBackground.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 36))
                                        .foregroundColor(.htzLabel.opacity(0.4))
                                )
                        @unknown default:
                            EmptyView()
                        }
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
