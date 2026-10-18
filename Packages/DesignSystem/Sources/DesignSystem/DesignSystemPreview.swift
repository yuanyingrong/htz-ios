import SwiftUI

struct DesignSystemPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HTZSpacing.lg) {
                Group {
                    Text("Colors").font(.htzLargeTitle)
                    HStack {
                        colorCircle(name: "Accent", color: .htzAccent)
                        colorCircle(name: "Background", color: .htzBackground)
                        colorCircle(name: "Label", color: .htzLabel)
                    }
                }
                
                Divider()
                
                Group {
                    Text("Typography").font(.htzLargeTitle)
                    VStack(alignment: .leading, spacing: HTZSpacing.sm) {
                        Text("Large Title").font(.htzLargeTitle)
                        Text("Title").font(.htzTitle)
                        Text("Headline").font(.htzHeadline)
                        Text("Body").font(.htzBody)
                        Text("Callout").font(.htzCallout)
                        Text("Subheadline").font(.htzSubheadline)
                        Text("Footnote").font(.htzFootnote)
                        Text("Caption").font(.htzCaption)
                    }
                }
                
                Divider()
                
                Group {
                    Text("Radius").font(.htzLargeTitle)
                    HStack {
                        radiusBox(name: "XS", radius: HTZRadius.xs)
                        radiusBox(name: "SM", radius: HTZRadius.sm)
                        radiusBox(name: "MD", radius: HTZRadius.md)
                        radiusBox(name: "LG", radius: HTZRadius.lg)
                        radiusBox(name: "XL", radius: HTZRadius.xl)
                    }
                }
            }
            .padding(HTZSpacing.md)
        }
        .background(Color.htzBackground)
        .foregroundColor(Color.htzLabel)
    }
    
    func colorCircle(name: String, color: Color) -> some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            Text(name).font(.htzCaption)
        }
    }
    
    func radiusBox(name: String, radius: CGFloat) -> some View {
        VStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.htzAccent)
                .frame(width: 50, height: 50)
            Text(name).font(.htzCaption)
        }
    }
}

#Preview {
    DesignSystemPreview()
}

#Preview {
    DesignSystemPreview()
        .preferredColorScheme(.light)
}
