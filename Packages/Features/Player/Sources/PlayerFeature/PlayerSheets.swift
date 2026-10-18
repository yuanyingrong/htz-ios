import SwiftUI
import DesignSystem

// Bottom sheets of the full player (倍速设置 / 分享至), styled after Android's dialogs:
// white card, 18 pt bold title, #4D4D4D text and a grey pill 「取消」 at the bottom.

private enum SheetStyle {
    static let ink = Color(red: 77 / 255, green: 77 / 255, blue: 77 / 255)
    static let hint = Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255)
    static let line = Color(red: 229 / 255, green: 229 / 255, blue: 229 / 255)
    static let grey = Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255)
    static let accent = Color(red: 1, green: 0.52, blue: 0.2)
}

private struct FittedHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Sizes a sheet to its content instead of a fixed detent.
private struct FittedSheet: ViewModifier {
    @State private var height: CGFloat = 320

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .background(GeometryReader { Color.clear.preference(key: FittedHeightKey.self, value: $0.size.height) })
            .onPreferenceChange(FittedHeightKey.self) { height = $0 }
            .presentationDetents([.height(height)])
            .presentationDragIndicator(.visible)
    }
}

private struct CancelPill: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("取消")
                .font(.system(size: 15))
                .foregroundColor(SheetStyle.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(SheetStyle.grey, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 倍速设置

struct SpeedSheet: View {
    let rate: Double
    let onSelect: (Double) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("倍速设置")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(SheetStyle.ink)
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 8)
            ForEach(PlayerFeature.rates, id: \.self) { value in
                let selected = abs(value - rate) < 0.01
                Button {
                    onSelect(value)
                    dismiss()
                } label: {
                    HStack {
                        Text("\(FullPlayerView.rateText(value)) 速播放")
                            .font(.system(size: 16, weight: selected ? .semibold : .regular))
                            .foregroundColor(selected ? SheetStyle.accent : SheetStyle.ink)
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(SheetStyle.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(SheetStyle.line).frame(height: 1).padding(.horizontal, 20)
                }
            }
            CancelPill { dismiss() }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
        }
        .modifier(FittedSheet())
    }
}

// MARK: - 分享至

struct ShareSheet: View {
    let content: ShareContent?
    let onWeChat: (WeChatScene) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("分享至")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(SheetStyle.ink)
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 16)
            HStack(alignment: .top, spacing: 0) {
                destination("微信", icon: HTZImage.shareWeChat) { onWeChat(.session) }
                destination("朋友圈", icon: HTZImage.shareMoments) { onWeChat(.timeline) }
                destination("收藏", icon: HTZImage.shareFavorite) { onWeChat(.favorite) }
                more
            }
            .padding(.horizontal, 16)
            CancelPill { dismiss() }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
        }
        .modifier(FittedSheet())
    }

    private func destination(_ title: String, icon: Image, action: @escaping () -> Void) -> some View {
        Button {
            action()
            dismiss()
        } label: {
            label(title) {
                icon.resizable().scaledToFit().frame(width: 40, height: 40)
            }
        }
        .buttonStyle(.plain)
        .disabled(content == nil)
    }

    /// iOS share sheet for everything else (Messages, Notes, copy link, other apps…).
    @ViewBuilder
    private var more: some View {
        if let content {
            ShareLink(
                item: content.url,
                subject: Text(content.title),
                message: Text("\(content.title) · \(content.description)")
            ) {
                label("更多") {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(SheetStyle.ink)
                        .frame(width: 40, height: 40)
                        .background(SheetStyle.grey, in: Circle())
                }
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(maxWidth: .infinity)
        }
    }

    private func label<Icon: View>(_ title: String, @ViewBuilder icon: () -> Icon) -> some View {
        VStack(spacing: 8) {
            icon()
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(SheetStyle.hint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
