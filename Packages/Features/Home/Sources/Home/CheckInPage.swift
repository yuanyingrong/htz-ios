import ComposableArchitecture
import DesignSystem
import NetworkKit
import SwiftUI

/// 「十年持志」打卡 H5. The page reads the login identity from localStorage on first render,
/// otherwise it asks to be opened inside WeChat.
struct CheckInPage: View {
    private static let lastUnionIdKey = "ten_year_last_union_id"

    @State private var profile: UserProfile?
    @State private var resetsSiteData = false
    @Dependency(\.library) private var library

    init(profile: UserProfile? = nil) {
        let known = profile.flatMap { $0.nickname.isEmpty ? nil : $0 }
        _profile = State(initialValue: known)
        _resetsSiteData = State(initialValue: known != nil && Self.consumeAccountSwitch())
    }

    var body: some View {
        if let profile {
            HTZWebPage(
                title: "每日打卡",
                url: WebPage.tenYears,
                localStorage: Self.storage(unionid: AuthManager.shared.unionid ?? "", profile: profile),
                resetsSiteData: resetsSiteData
            )
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .htzPage("每日打卡")
                .task {
                    let loaded = (try? await library.profile()) ?? UserProfile()
                    resetsSiteData = Self.consumeAccountSwitch()
                    profile = loaded
                }
        }
    }

    /// True when a different account (or none) opened the page last time; H5 caches that account's profile.
    private static func consumeAccountSwitch() -> Bool {
        let unionid = AuthManager.shared.unionid ?? ""
        let defaults = UserDefaults.standard
        let switched = defaults.string(forKey: lastUnionIdKey) != unionid
        defaults.set(unionid, forKey: lastUnionIdKey)
        return switched
    }

    static func storage(unionid: String, profile: UserProfile) -> [String: String] {
        guard !unionid.isEmpty else { return [:] }
        return [
            "unionid": unionid,
            "htz_nickname": profile.nickname,
            "htz_headimgurl": profile.avatar,
            "htz_city": profile.city,
            "htz_province": profile.province,
            "htz_gender": profile.sex == 1 ? "1" : (profile.sex == 2 ? "2" : "")
        ]
    }
}
