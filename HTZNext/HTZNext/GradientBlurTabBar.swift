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

/// Tab container styled after the Android app: a flat white bar with a hairline top divider.
struct CustomTabView<Content: View>: View {
    @Binding var selection: Int
    let tabs: [TabConfig]
    var tabBarHeight: CGFloat
    var selectedColor: Color
    @ViewBuilder let content: (Int) -> Content

    init(
        selection: Binding<Int>,
        tabs: [TabConfig],
        tabBarHeight: CGFloat = 58,
        selectedColor: Color = .accentColor,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self._selection = selection
        self.tabs = tabs
        self.tabBarHeight = tabBarHeight
        self.selectedColor = selectedColor
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                ForEach(tabs) { tab in
                    content(tab.id)
                        .opacity(selection == tab.id ? 1 : 0)
                        .allowsHitTesting(selection == tab.id)
                        .zIndex(selection == tab.id ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(red: 238 / 255, green: 238 / 255, blue: 238 / 255))
                    .frame(height: 0.5)
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        TabBarItemView(
                            title: tab.title,
                            icon: tab.icon,
                            isSelected: selection == tab.id,
                            accentColor: selectedColor
                        )
                        .onTapGesture { selection = tab.id }
                    }
                }
                .frame(height: tabBarHeight)
            }
            .background(Color.white.ignoresSafeArea(edges: .bottom))
        }
    }
}

// MARK: - Tab Bar Item View

private struct TabBarItemView: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let accentColor: Color

    private let unselectedColor = Color(red: 138 / 255, green: 138 / 255, blue: 138 / 255)

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: isSelected ? .semibold : .regular))
            Text(title)
                .font(.system(size: 11))
        }
        .foregroundColor(isSelected ? accentColor : unselectedColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
