import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit

public struct LoginView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<AuthFeature>
    
    // Animation States
    @State private var isAnimated = false
    @State private var showButton = false
    @State private var legalPage: LegalPage?
    
    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                // 1. Base Background Color
                Color.htzBackground
                    .ignoresSafeArea()
                
                // 2. Extremely Subtle Warm Glow (mimicking Journal paper/light texture)
                RadialGradient(
                    colors: [Color.htzAccent.opacity(0.04), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 600
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                // 3. Layout (Apple Minimalist Style, 5-6 core elements max)
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 120)
                    
                    // Element 1: Logo
                    Image("login_logo", bundle: .main)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: HTZRadius.md))
                        .opacity(isAnimated ? 1.0 : 0.0)
                    
                    Spacer()
                        .frame(height: HTZSpacing.lg)
                    
                    // Element 2 & 3: App Name & Slogan Group
                    VStack(spacing: HTZSpacing.sm) {
                        Text("黄庭禅")
                            .font(.htzTitle)
                            .tracking(2)
                            .foregroundStyle(Color.htzLabel)
                        
                        Text("回归内心")
                            .font(.htzSubheadline)
                            .tracking(1)
                            .foregroundStyle(Color.secondary)
                    }
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .offset(y: isAnimated ? 0 : 12)
                    
                    Spacer()
                    
                    // Element 4: Monochrome Login Button (WeChat Continue style)
                    VStack(spacing: 0) {
                        Button(action: {
                            store.send(.wechatLoginTapped)
                        }) {
                            HStack(spacing: HTZSpacing.sm) {
                                if store.isLoading {
                                    ProgressView()
                                        .tint(Color.htzBackground)
                                } else {
                                    Image("wechat", bundle: .main)
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 22, height: 22)
                                    
                                    Text("继续使用微信")
                                        .font(.htzHeadline)
                                        .bold()
                                }
                            }
                            .foregroundColor(Color.htzBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.htzLabel)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(PremiumButtonStyle())
                        .disabled(store.isLoading)
                        .padding(.horizontal, 40)

                        Button("手机号登录") {
                            store.send(.phoneLoginTapped)
                        }
                        .font(.htzSubheadline)
                        .foregroundStyle(Color.secondary)
                        .padding(.top, HTZSpacing.md)
                        .disabled(store.isLoading)
                    }
                    .opacity(showButton ? 1.0 : 0.0)
                    .offset(y: showButton ? 0 : 10)
                    
                    Spacer()
                        .frame(height: 100)
                    
                    // Element 5: Terms & Policies Flow
                    HStack(spacing: 0) {
                        Text("登录即代表阅读并同意")
                            .foregroundColor(.secondary)
                        Button("《用户协议》") { legalPage = .agreement }
                            .foregroundColor(HTZColor.orange)
                        Text("与")
                            .foregroundColor(.secondary)
                        Button("《隐私政策》") { legalPage = .privacy }
                            .foregroundColor(HTZColor.orange)
                    }
                    .font(.htzCaption)
                    .padding(.horizontal, 24)
                    .padding(.bottom, HTZSpacing.lg)
                }
            }
            .alert(
                "提示",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            store.send(.clearError)
                        }
                    }
                ),
                actions: {
                    Button("确定") {
                        store.send(.clearError)
                    }
                },
                message: {
                    Text(store.errorMessage ?? "")
                }
            )
            .sheet(item: $store.scope(state: \.phoneLogin, action: \.phoneLogin)) { store in
                PhoneLoginView(store: store)
            }
            .sheet(item: $legalPage) { page in
                NavigationStack {
                    HTZWebPage(title: page.title, url: page.url)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("关闭") { legalPage = nil }
                            }
                        }
                }
            }
            .onAppear {
                // Entry Animations with easeOut transitions
                withAnimation(.easeOut(duration: 0.5)) {
                    isAnimated = true
                }
                
                // 0.1s delayed button entrance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showButton = true
                    }
                }
            }
        }
    }
}

// MARK: - PremiumButtonStyle
struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private enum LegalPage: String, Identifiable {
    case agreement
    case privacy

    var id: String { rawValue }

    var title: String {
        self == .agreement ? "用户协议" : "隐私政策"
    }

    var url: URL {
        self == .agreement ? WebPage.agreement : WebPage.privacy
    }
}
