import SwiftUI

// Bottom confirmation sheet modelled on Android's `dialog_bottom_confirm`:
// drag indicator, centred 18 pt bold title, grey 14 pt message, and an
// orange 「确定」 pill next to a grey 「取消」 pill.

private struct ConfirmSheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct HTZConfirmSheetContent: View {
    let title: String
    let message: String
    let confirmTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var height: CGFloat = 240

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HTZColor.title)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 28)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(HTZColor.hint)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            HStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(HTZColor.cta, in: Capsule())
                }
                Button(action: onCancel) {
                    Text("取消")
                        .font(.system(size: 15))
                        .foregroundColor(HTZColor.title)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: 0xF0F0F0), in: Capsule())
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(GeometryReader { Color.clear.preference(key: ConfirmSheetHeightKey.self, value: $0.size.height) })
        .onPreferenceChange(ConfirmSheetHeightKey.self) { height = $0 }
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.visible)
        .modifier(ConfirmSheetBackground())
    }
}

private struct ConfirmSheetBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            // Opaque white: iOS 26 would otherwise render a translucent glass sheet.
            content.presentationCornerRadius(24).presentationBackground(Color.white)
        } else {
            content
        }
    }
}

public extension View {
    /// Android-style bottom confirmation sheet (系统提示 + 确定 / 取消).
    func htzConfirmSheet(
        isPresented: Binding<Bool>,
        title: String = "系统提示",
        message: String,
        confirmTitle: String = "确定",
        onConfirm: @escaping () -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            HTZConfirmSheetContent(
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                onConfirm: {
                    isPresented.wrappedValue = false
                    onConfirm()
                },
                onCancel: { isPresented.wrappedValue = false }
            )
        }
    }
}
