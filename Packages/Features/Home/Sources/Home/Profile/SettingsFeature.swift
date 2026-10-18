import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature
import SwiftUI

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        @Shared(.checkInEnabled) public var isCheckInEnabled = false
        public var isRestoreConfirmPresented = false
        public var isLogoutConfirmPresented = false
        public var helpHTML: String?
        public var toast: String?

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case helpTapped
        case helpLoaded(String)
        case helpFailed
        case restoreConfirmed
        case logoutConfirmed
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case openFeedback
            case logout
        }
    }

    @Dependency(\.library) var library

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                return .none

            case .helpTapped:
                return .run { send in
                    do {
                        await send(.helpLoaded(try await library.helpDocument()))
                    } catch {
                        await send(.helpFailed)
                    }
                }

            case let .helpLoaded(markdown):
                state.helpHTML = SimpleMarkdown.html(markdown)
                return .none

            case .helpFailed:
                state.toast = "帮助文档加载失败"
                return .none

            case .restoreConfirmed:
                AppSettings.restoreDefaults()
                state.toast = "已恢复默认设置"
                return .none

            case .logoutConfirmed:
                return .send(.delegate(.logout))
            }
        }
    }
}

struct SettingsView: View {
    @Perception.Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(spacing: 12) {
                    group {
                        HTZSwitchRow("每日打卡", subtitle: "在首页和我的页面显示打卡入口", isOn: $store.isCheckInEnabled)
                    }
                    group {
                        HTZMenuRow(title: "版本号", value: "\(AppInfo.version)（\(AppInfo.build)）", showsChevron: false)
                        HTZDivider()
                        Button { store.send(.helpTapped) } label: { HTZMenuRow(title: "功能帮助") }
                            .buttonStyle(.plain)
                        HTZDivider()
                        Button { store.send(.delegate(.openFeedback)) } label: { HTZMenuRow(title: "意见反馈") }
                            .buttonStyle(.plain)
                        HTZDivider()
                        NavigationLink { HTZWebPage(title: "用户协议", url: WebPage.agreement) } label: { HTZMenuRow(title: "用户协议") }
                            .buttonStyle(.plain)
                        HTZDivider()
                        NavigationLink { HTZWebPage(title: "隐私政策", url: WebPage.privacy) } label: { HTZMenuRow(title: "隐私政策") }
                            .buttonStyle(.plain)
                        HTZDivider()
                        Button { store.send(.binding(.set(\.isRestoreConfirmPresented, true))) } label: { HTZMenuRow(title: "恢复默认设置") }
                            .buttonStyle(.plain)
                        HTZDivider()
                        NavigationLink { AboutAcademyView() } label: { HTZMenuRow(title: "关于黄庭书院") }
                            .buttonStyle(.plain)
                    }
                    group {
                        Button { store.send(.binding(.set(\.isLogoutConfirmPresented, true))) } label: {
                            Text("退出登录")
                                .font(.system(size: 15))
                                .foregroundColor(HTZColor.danger)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(HTZColor.card)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            .htzPage("系统设置")
            .htzToast($store.toast)
            .navigationDestination(isPresented: Binding(
                get: { store.helpHTML != nil },
                set: { if !$0 { store.send(.binding(.set(\.helpHTML, nil))) } }
            )) {
                if let html = store.helpHTML {
                    HTZWebPage(title: "功能帮助", content: .html(html, baseURL: WebPage.help))
                }
            }
            .htzConfirmSheet(
                isPresented: $store.isRestoreConfirmPresented,
                title: "提示",
                message: "恢复默认设置将重置播放模式、歌词字号和打卡开关，不会影响登录状态和已下载内容。确定要恢复吗？"
            ) { store.send(.restoreConfirmed) }
            .htzConfirmSheet(
                isPresented: $store.isLogoutConfirmPresented,
                message: "确定要退出登录吗？登录后功能使用更精彩"
            ) { store.send(.logoutConfirmed) }
        }
    }

    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0, content: content)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct AboutAcademyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("书院初衷与愿景")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: 0x292929))
                ForEach(paragraphs, id: \.self) { text in
                    Text(text)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: 0x555555))
                        .lineSpacing(6)
                }
                Link(destination: WebPage.academy) {
                    Text("内容参考黄庭禅官方网站「初衷与愿景」")
                        .font(.system(size: 13))
                        .foregroundColor(HTZColor.hint)
                        .underline()
                }
            }
            .padding(20)
        }
        .background(Color.white)
        .htzPage("关于黄庭书院")
    }

    private let paragraphs = [
        "黄庭书院以传承圣贤安心立命之学为愿，致力于引导人们观察本心、认识本性，在日常生活中看见烦恼的来处，走向内心的安宁与自在。",
        "书院希望打造一处不拘宗派、平等探讨真理的学习之地。来到这里，不以派别相较，只共同探问本心本性与清静解脱之道。",
        "书院所开设的禅修课程称为“黄庭禅”，通过觉察身心当下的变化，学习在生活的喜怒哀乐中照见自己，逐步理解并安顿内心。"
    ]
}
