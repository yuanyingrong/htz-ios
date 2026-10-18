import ComposableArchitecture
import NetworkKit
import XCTest
@testable import AuthFeature

@MainActor
final class PhoneLoginFeatureTests: XCTestCase {
    func testUnregisteredPhoneAsksForWeChatFirst() async {
        var state = PhoneLoginFeature.State()
        state.phone = "13800000000"
        state.code = "1234"
        let store = TestStore(initialState: state) {
            PhoneLoginFeature()
        } withDependencies: {
            $0.library.loginWithPhone = { _, _ in throw PhoneLoginError.notRegistered }
        }
        await store.send(.submitTapped) {
            $0.isSubmitting = true
        }
        await store.receive(\.failed) {
            $0.isSubmitting = false
            $0.message = "该手机号尚未绑定账号，请先使用微信登录，并在「我的 - 个人信息」中绑定手机号"
        }
    }

    func testSuccessfulLoginLogsInParent() async {
        var state = AuthFeature.State()
        state.isLoggedIn = false
        state.phoneLogin = PhoneLoginFeature.State()
        let store = TestStore(initialState: state) {
            AuthFeature()
        } withDependencies: {
            $0.library.loginWithPhone = { _, _ in }
        }
        await store.send(\.phoneLogin.binding.phone, "13800000000") {
            $0.phoneLogin?.phone = "13800000000"
        }
        await store.send(\.phoneLogin.binding.code, "123456") {
            $0.phoneLogin?.code = "123456"
        }
        await store.send(\.phoneLogin.submitTapped) {
            $0.phoneLogin?.isSubmitting = true
        }
        await store.receive(\.phoneLogin.loginFinished) {
            $0.phoneLogin?.isSubmitting = false
        }
        await store.receive(\.phoneLogin.delegate) {
            $0.phoneLogin = nil
            $0.isLoggedIn = true
        }
    }
}
