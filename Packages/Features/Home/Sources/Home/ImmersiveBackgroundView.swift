import SwiftUI

public struct ImmersiveBackgroundView: View {
    let imageUrl: URL?
    
    public init(imageUrl: URL?) {
        self.imageUrl = imageUrl
    }
    
    public var body: some View {
        ZStack {
            Color.htzBackground
            
            AsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .blur(radius: 60)
                    .overlay(Color.black.opacity(0.2))
                    .clipped() // 强制裁剪，防止撑大界面
            } placeholder: {
                Color.htzBackground
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ImmersiveBackgroundView(imageUrl: URL(string: "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/production/690893fabfd2bf16f3f128ff"))
}
