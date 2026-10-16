import SwiftUI

// MARK: - Tab Configuration

/// Configuration for a single tab in the custom tab bar.
struct TabConfig: Identifiable {
    let id: Int
    let title: String
    let icon: String

    init(id: Int, title: String, icon: String) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}

// MARK: - Custom Tab View

/// A tab view container that renders a gradient blur fade above the tab bar,
/// mimicking the Apple Music / Apple Podcasts tab bar effect.
///
/// The blur uses real `.ultraThinMaterial` masked with a vertical alpha gradient,
/// so content behind the bar appears correctly blurred regardless of background.
///
/// Usage:
/// ```swift
/// CustomTabView(selection: $tab, tabs: tabs, selectedColor: .orange) { id in
///     switch id {
///     case 0: HomeView()
///     case 1: BrowseView()
///     default: EmptyView()
///     }
/// }
/// ```
struct CustomTabView<Content: View>: View {

    @Binding var selection: Int
    let tabs: [TabConfig]
    var fadeHeight: CGFloat = 80
    var tabBarHeight: CGFloat = 49
    var selectedColor: Color = .accentColor
    @ViewBuilder let content: (Int) -> Content

    init(
        selection: Binding<Int>,
        tabs: [TabConfig],
        fadeHeight: CGFloat = 80,
        tabBarHeight: CGFloat = 49,
        selectedColor: Color = .accentColor,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self._selection = selection
        self.tabs = tabs
        self.fadeHeight = fadeHeight
        self.tabBarHeight = tabBarHeight
        self.selectedColor = selectedColor
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            let safeBottom = geo.safeAreaInsets.bottom
            let blurTotalHeight = fadeHeight + tabBarHeight + safeBottom

            ZStack {

                // ── Layer 1: Content (full screen) ──────────────────────
                ZStack {
                    ForEach(tabs) { tab in
                        content(tab.id)
                            .opacity(selection == tab.id ? 1 : 0)
                            .allowsHitTesting(selection == tab.id)
                            .zIndex(selection == tab.id ? 1 : 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Layer 2: Gradient blur (pinned to screen bottom) ────
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(alignment: .top) {
                            VStack(spacing: 0) {
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .white, location: 1),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: fadeHeight)
                                Color.white
                                    .frame(height: tabBarHeight + safeBottom)
                            }
                        }
                        .frame(height: blurTotalHeight)
                        .allowsHitTesting(false)
                }
                .ignoresSafeArea()

                // ── Layer 3: Tab bar controls ───────────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    TabBarControlView(
                        tabs: tabs,
                        selection: $selection,
                        selectedColor: selectedColor
                    )
                    .frame(height: tabBarHeight)
                }
            }
        }
    }
}

// MARK: - Tab Bar Control View

/// The visible tab bar row: a divider line + tab item buttons.
/// The background is intentionally transparent — the blur layer behind
/// this view provides the material effect.
private struct TabBarControlView: View {
    let tabs: [TabConfig]
    @Binding var selection: Int
    let selectedColor: Color

    var body: some View {
        VStack(spacing: 0) {

            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    TabBarItemView(
                        title: tab.title,
                        icon: tab.icon,
                        isSelected: selection == tab.id,
                        accentColor: selectedColor
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = tab.id
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Tab Bar Item View

/// A single tab button: icon + label with selected/unselected styling.
private struct TabBarItemView: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let accentColor: Color

    private let unselectedColor: Color = .secondary

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
        }
        .foregroundStyle(isSelected ? accentColor : unselectedColor)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .scaleEffect(isSelected ? 1.0 : 0.97)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
