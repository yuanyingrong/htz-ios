import SwiftUI

/// Palette shared with the Android app (`res/values/colors.xml`). The app has no dark theme.
public enum HTZColor {
    public static let page = Color(hex: 0xF4F4F4)
    public static let card = Color.white
    public static let title = Color(hex: 0x4D4D4D)
    public static let secondary = Color(hex: 0x666666)
    public static let hint = Color(hex: 0x999999)
    public static let tabNormal = Color(hex: 0x8A8A8A)
    public static let divider = Color(hex: 0xEEEEEE)
    public static let stroke = Color(hex: 0xE2E2E2)
    public static let field = Color(hex: 0xE8E8E8)
    public static let warm = Color(hex: 0xECE1D3)
    public static let statsAccent = Color(hex: 0xC08A4B)
    public static let statsTrack = Color(hex: 0xEDE4D8)
    public static let orange = Color(hex: 0xFF8C00)
    public static let ctaStart = Color(hex: 0xFF6B35)
    public static let ctaEnd = Color(hex: 0xF7931E)
    public static let price = Color(hex: 0xFF5722)
    public static let trial = Color(hex: 0x4CAF50)
    public static let switchOn = Color(hex: 0x07C160)
    public static let danger = Color(hex: 0xE53935)

    public static let cta = LinearGradient(colors: [ctaStart, ctaEnd], startPoint: .leading, endPoint: .trailing)
}

public extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Containers

public struct HTZCard<Content: View>: View {
    private let radius: CGFloat
    private let content: Content

    public init(radius: CGFloat = 15, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HTZColor.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

public struct HTZSectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(HTZColor.title)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right").font(.system(size: 11))
                    }
                    .font(.system(size: 13))
                    .foregroundColor(HTZColor.hint)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A white settings/menu row: optional icon, title, trailing value, red dot and chevron.
public struct HTZMenuRow: View {
    private let icon: String?
    private let title: String
    private let value: String?
    private let showsDot: Bool
    private let showsChevron: Bool

    public init(icon: String? = nil, title: String, value: String? = nil, showsDot: Bool = false, showsChevron: Bool = true) {
        self.icon = icon
        self.title = title
        self.value = value
        self.showsDot = showsDot
        self.showsChevron = showsChevron
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(HTZColor.title)
                    .frame(width: 24)
            }
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(HTZColor.title)
            if showsDot {
                Circle().fill(HTZColor.danger).frame(width: 7, height: 7)
            }
            Spacer(minLength: 8)
            if let value, !value.isEmpty {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(HTZColor.hint)
                    .lineLimit(1)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(HTZColor.hint)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(HTZColor.card)
        .contentShape(Rectangle())
    }
}

public struct HTZSwitchRow: View {
    private let title: String
    private let subtitle: String?
    @Binding private var isOn: Bool

    public init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(HTZColor.title)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(HTZColor.hint)
                }
            }
        }
        .tint(HTZColor.switchOn)
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(HTZColor.card)
    }
}

public struct HTZDivider: View {
    private let leading: CGFloat

    public init(leading: CGFloat = 16) {
        self.leading = leading
    }

    public var body: some View {
        Rectangle()
            .fill(HTZColor.divider)
            .frame(height: 0.5)
            .padding(.leading, leading)
    }
}

// MARK: - Buttons & badges

public struct HTZPrimaryButtonStyle: ButtonStyle {
    private let height: CGFloat

    public init(height: CGFloat = 44) {
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(HTZColor.cta, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Small gradient pill used for inline actions such as 续播 / 立即购买.
public struct HTZPillButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .frame(height: 30)
            .background(HTZColor.cta, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

public struct HTZBadge: View {
    public enum Kind { case paid, purchased, trial }

    private let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(background)
    }

    private var text: String {
        switch kind {
        case .paid: return "付费"
        case .purchased: return "已购"
        case .trial: return "试听"
        }
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .paid: RoundedRectangle(cornerRadius: 10).fill(HTZColor.cta)
        case .purchased: RoundedRectangle(cornerRadius: 10).fill(HTZColor.statsAccent)
        case .trial: RoundedRectangle(cornerRadius: 8).fill(HTZColor.trial)
        }
    }
}

// MARK: - Images & empty states

public struct HTZRemoteImage: View {
    private let url: URL?
    private let radius: CGFloat

    public init(_ url: URL?, radius: CGFloat = 4) {
        self.url = url
        self.radius = radius
    }

    public init(_ string: String?, radius: CGFloat = 4) {
        self.init(string.flatMap(URL.init(string:)), radius: radius)
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image):
                image.resizable().scaledToFill()
            default:
                ZStack {
                    HTZColor.warm
                    Image(systemName: "music.note")
                        .foregroundColor(HTZColor.statsAccent.opacity(0.6))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

public struct HTZEmptyView: View {
    private let text: String
    private let icon: String

    public init(_ text: String = "暂无数据", icon: String = "tray") {
        self.text = text
        self.icon = icon
    }

    public var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(HTZColor.hint.opacity(0.6))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(HTZColor.hint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

/// A transient centered message, like Android's center toast.
public struct HTZToast: ViewModifier {
    @Binding private var message: String?

    public init(message: Binding<String?>) {
        self._message = message
    }

    public func body(content: Content) -> some View {
        content.overlay {
            if let message {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
                    .padding(40)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .task(id: message) {
                        try? await Task.sleep(nanoseconds: 1_800_000_000)
                        withAnimation { self.message = nil }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}

public extension View {
    func htzToast(_ message: Binding<String?>) -> some View {
        modifier(HTZToast(message: message))
    }

    /// Android-style page chrome: grey background and a light inline navigation bar.
    func htzPage(_ title: String? = nil) -> some View {
        self
            .background(HTZColor.page.ignoresSafeArea())
            .navigationTitle(title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
