import ComposableArchitecture
import DesignSystem
import NetworkKit
import SwiftUI

@Reducer
public struct PhoneLoginFeature {
    @ObservableState
    public struct State: Equatable {
        public var phone = ""
        public var code = ""
        public var countdown = 0
        public var isSending = false
        public var isSubmitting = false
        public var message: String?

        public init() {}

        var isPhoneValid: Bool {
            phone.count == 11 && phone.hasPrefix("1") && phone.allSatisfy(\.isNumber)
        }

        var canSubmit: Bool {
            isPhoneValid && code.count >= 4 && !isSubmitting
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case sendCodeTapped
        case codeSent
        case tick
        case submitTapped
        case loginFinished
        case failed(String)
        case closeTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case loggedIn
        }
    }

    @Dependency(\.library) var library
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                state.phone = String(state.phone.filter(\.isNumber).prefix(11))
                state.code = String(state.code.filter(\.isNumber).prefix(6))
                return .none

            case .sendCodeTapped:
                guard state.isPhoneValid else {
                    state.message = "请输入正确的手机号"
                    return .none
                }
                guard state.countdown == 0, !state.isSending else { return .none }
                state.isSending = true
                let phone = state.phone
                return .run { send in
                    do {
                        try await library.sendSms(phone)
                        await send(.codeSent)
                    } catch {
                        await send(.failed("验证码发送失败，请稍后重试"))
                    }
                }

            case .codeSent:
                state.isSending = false
                state.countdown = 60
                state.message = "验证码已发送"
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: CountdownID(), cancelInFlight: true)

            case .tick:
                state.countdown = max(0, state.countdown - 1)
                return state.countdown == 0 ? .cancel(id: CountdownID()) : .none

            case .submitTapped:
                guard state.canSubmit else { return .none }
                state.isSubmitting = true
                let phone = state.phone
                let code = state.code
                return .run { send in
                    do {
                        try await library.loginWithPhone(phone, code)
                        await send(.loginFinished)
                    } catch PhoneLoginError.notRegistered {
                        await send(.failed("该手机号尚未绑定账号，请先使用微信登录，并在「我的 - 个人信息」中绑定手机号"))
                    } catch let NetworkError.apiError(message) {
                        await send(.failed(message.isEmpty ? "登录失败" : message))
                    } catch {
                        await send(.failed("登录失败，请检查验证码"))
                    }
                }

            case .loginFinished:
                state.isSubmitting = false
                return .merge(.cancel(id: CountdownID()), .send(.delegate(.loggedIn)))

            case let .failed(message):
                state.isSending = false
                state.isSubmitting = false
                state.message = message
                return .none

            case .closeTapped:
                return .run { _ in await dismiss() }

            case .delegate:
                return .none
            }
        }
    }
}

private struct CountdownID: Hashable {}

struct PhoneLoginView: View {
    @Perception.Bindable var store: StoreOf<PhoneLoginFeature>

    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            Text("+86")
                                .foregroundColor(HTZColor.title)
                            TextField("请输入手机号", text: $store.phone)
                                .keyboardType(.numberPad)
                                .textContentType(.telephoneNumber)
                        }
                        .frame(height: 52)
                        HTZDivider(leading: 0)
                        HStack {
                            TextField("请输入验证码", text: $store.code)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                            Button {
                                store.send(.sendCodeTapped)
                            } label: {
                                Text(store.countdown > 0 ? "\(store.countdown)s 后重发" : "获取验证码")
                                    .font(.system(size: 14))
                                    .foregroundColor(store.countdown > 0 ? HTZColor.hint : HTZColor.orange)
                            }
                            .disabled(store.countdown > 0 || store.isSending)
                        }
                        .frame(height: 52)
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .background(HTZColor.card, in: RoundedRectangle(cornerRadius: 10))
                    .padding(16)

                    Button {
                        store.send(.submitTapped)
                    } label: {
                        if store.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("登录")
                        }
                    }
                    .buttonStyle(HTZPrimaryButtonStyle())
                    .disabled(!store.canSubmit)
                    .opacity(store.canSubmit ? 1 : 0.5)
                    .padding(.horizontal, 16)

                    Text("仅支持已绑定手机号的账号登录")
                        .font(.system(size: 12))
                        .foregroundColor(HTZColor.hint)
                        .padding(.top, 12)
                    Spacer()
                }
                .background(HTZColor.page.ignoresSafeArea())
                .navigationTitle("手机号登录")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") { store.send(.closeTapped) }
                    }
                }
                .htzToast($store.message)
            }
        }
    }
}
