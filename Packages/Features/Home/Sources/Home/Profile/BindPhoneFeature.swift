import ComposableArchitecture
import DesignSystem
import NetworkKit
import SwiftUI

@Reducer
public struct BindPhoneFeature {
    @ObservableState
    public struct State: Equatable {
        public var phone = ""
        public var code = ""
        public var countdown = 0
        public var isSubmitting = false
        public var toast: String?

        public init(phone: String = "") {
            self.phone = phone
        }

        public var isPhoneValid: Bool { PhoneNumber.isValid(phone) }
        public var canSubmit: Bool { isPhoneValid && code.count >= 4 && !isSubmitting }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case sendCodeTapped
        case codeSent
        case tick
        case submitTapped
        case failed(String)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case bound(String)
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
            case .binding, .delegate:
                return .none

            case .sendCodeTapped:
                guard state.isPhoneValid else {
                    state.toast = "请输入正确的手机号"
                    return .none
                }
                guard state.countdown == 0 else { return .none }
                state.countdown = 60
                let phone = state.phone
                return .merge(
                    .run { send in
                        do {
                            try await library.sendSms(phone)
                            await send(.codeSent)
                        } catch {
                            await send(.failed("验证码发送失败"))
                        }
                    },
                    .run { send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.tick)
                        }
                    }
                    .cancellable(id: CountdownID.timer, cancelInFlight: true)
                )

            case .codeSent:
                state.toast = "验证码已发送"
                return .none

            case .tick:
                state.countdown = max(0, state.countdown - 1)
                return state.countdown == 0 ? .cancel(id: CountdownID.timer) : .none

            case .submitTapped:
                guard state.canSubmit else { return .none }
                state.isSubmitting = true
                let phone = state.phone
                let code = state.code
                return .run { send in
                    do {
                        try await library.bindTelephone(phone, code)
                        await send(.delegate(.bound(phone)))
                        await dismiss()
                    } catch let NetworkError.apiError(message) {
                        await send(.failed(message))
                    } catch {
                        await send(.failed("绑定失败，请检查验证码"))
                    }
                }

            case let .failed(message):
                state.isSubmitting = false
                state.toast = message
                if message == "验证码发送失败" {
                    state.countdown = 0
                    return .cancel(id: CountdownID.timer)
                }
                return .none
            }
        }
    }
}

private enum CountdownID: Hashable { case timer }

enum PhoneNumber {
    static func isValid(_ phone: String) -> Bool {
        phone.count == 11 && phone.hasPrefix("1") && phone.allSatisfy(\.isNumber)
    }

    static func masked(_ phone: String) -> String {
        guard phone.count == 11 else { return phone }
        return phone.prefix(3) + "****" + phone.suffix(4)
    }
}

/// Phone + SMS code fields shared by binding and phone login.
struct PhoneCodeFields: View {
    @Binding var phone: String
    @Binding var code: String
    let countdown: Int
    let onSendCode: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("+86").foregroundColor(HTZColor.title)
                TextField("请输入手机号", text: $phone)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
            }
            .frame(height: 52)
            HTZDivider(leading: 0)
            HStack {
                TextField("请输入验证码", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                Button(countdown > 0 ? "\(countdown)s后重发" : "获取验证码", action: onSendCode)
                    .font(.system(size: 14))
                    .foregroundColor(countdown > 0 ? HTZColor.hint : HTZColor.ctaStart)
                    .disabled(countdown > 0)
            }
            .frame(height: 52)
        }
        .font(.system(size: 15))
        .padding(.horizontal, 16)
        .background(HTZColor.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct BindPhoneView: View {
    @Perception.Bindable var store: StoreOf<BindPhoneFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 24) {
                PhoneCodeFields(
                    phone: $store.phone,
                    code: $store.code,
                    countdown: store.countdown
                ) {
                    store.send(.sendCodeTapped)
                }
                Button {
                    store.send(.submitTapped)
                } label: {
                    if store.isSubmitting { ProgressView().tint(.white) } else { Text("绑定") }
                }
                .buttonStyle(HTZPrimaryButtonStyle())
                .disabled(!store.canSubmit)
                .opacity(store.canSubmit ? 1 : 0.5)
                Spacer()
            }
            .padding(16)
            .htzPage("绑定手机号")
            .htzToast($store.toast)
        }
    }
}
