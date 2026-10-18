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

/// Bitmap icons copied from the Android app (`res/drawable-hdpi`).
public enum HTZImage {
    /// `albums_title.png` — the bar-wave mark in front of 「推荐专辑」.
    public static var waveTitle: Image { Image("htzWaveTitle", bundle: .module) }
    /// `home_listview_bg_0/1/2.png` — the painted banners Android falls back to when a recommendation has no background URL.
    public static func homeBanner(_ index: Int) -> Image { Image("htzHomeBanner\(index % 3)", bundle: .module) }
    public static func sort(ascending: Bool) -> Image { Image(ascending ? "htzSortAscending" : "htzSortDescending", bundle: .module) }
    public static var menu: Image { Image("htzMenu", bundle: .module) }
    public static var download: Image { Image("htzDownload", bundle: .module) }
    public static var downloaded: Image { Image("htzDownloaded", bundle: .module) }
    public static var playCount: Image { Image("htzPlayCount", bundle: .module) }
    public static var time: Image { Image("htzTime", bundle: .module) }
    public static var shareWeChat: Image { Image("htzShareWeChat", bundle: .module) }
    public static var shareMoments: Image { Image("htzShareMoments", bundle: .module) }
    public static var shareFavorite: Image { Image("htzShareFavorite", bundle: .module) }
    /// `history_item.png` — the calendar button at the right of the search bar.
    public static var historyButton: Image { Image("htzHistoryButton", bundle: .module) }
}

/// Port of Android's `AnimatedBarsView`: four #666 bars, left aligned, bouncing between 15 % and 55 % of the height.
public struct HTZAnimatedBars: View {
    private let isAnimating: Bool

    public init(isAnimating: Bool) {
        self.isAnimating = isAnimating
    }

    public var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 12
            ZStack(alignment: .topLeading) {
                ForEach(0..<4, id: \.self) { index in
                    Bar(index: index, isAnimating: isAnimating, height: geo.size.height)
                        .frame(width: unit, height: geo.size.height)
                        .offset(x: CGFloat(index) * 2 * unit)
                }
            }
        }
    }

    private struct Bar: View {
        let index: Int
        let isAnimating: Bool
        let height: CGFloat
        @State private var high = false

        private static let resting: [CGFloat] = [0.35, 0.5, 0.25, 0.45]

        var body: some View {
            let fraction: CGFloat = isAnimating ? (high ? 0.55 : 0.15) : Self.resting[index]
            Rectangle()
                .fill(Color(hex: 0x666666))
                .frame(height: height * fraction)
                .frame(maxHeight: .infinity)
                .onAppear { update() }
                .onChange(of: isAnimating) { _ in update() }
        }

        private func update() {
            if isAnimating {
                high = false
                withAnimation(.easeInOut(duration: 0.5 + 0.1 * Double(index)).repeatForever(autoreverses: true)) { high = true }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) { high = false }
            }
        }
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
            .modifier(HTZSubpageMarker())
    }
}

/// Tracks which pushed pages are on screen so the app shell can hide its custom tab bar
/// whenever the user is inside a sub-feature (like a pushed `UIViewController` hiding the bottom bar).
public final class HTZChrome: ObservableObject {
    public static let shared = HTZChrome()

    @Published public private(set) var subpageCount = 0
    private var visible = Set<UUID>()

    public var isInSubpage: Bool { subpageCount > 0 }

    fileprivate func appear(_ id: UUID) {
        visible.insert(id)
        subpageCount = visible.count
    }

    /// Removal is deferred one run-loop turn: when popping from page B to page A, A's `onAppear` and
    /// B's `onDisappear` arrive in either order, and removing eagerly would flash the tab bar.
    fileprivate func disappear(_ id: UUID) {
        DispatchQueue.main.async { [self] in
            visible.remove(id)
            subpageCount = visible.count
        }
    }
}

private struct HTZSubpageMarker: ViewModifier {
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear { HTZChrome.shared.appear(id) }
            .onDisappear { HTZChrome.shared.disappear(id) }
    }
}
