import XCTest
import ComposableArchitecture
import NetworkKit
import PlayerFeature
@testable import DesignSystem
@testable import Home

final class HomeTests: XCTestCase {
    func testPackageLoads() {
        XCTAssertNotNil(HomeFeature.State())
    }

    func testChaptersDefaultToAscendingLessonOrder() {
        let items = [
            SutraItem(id: "c", title: "003.第三", lesson: 3),
            SutraItem(id: "a", title: "001.第一", lesson: 1),
            SutraItem(id: "b", title: "002.第二", lesson: 2)
        ]
        XCTAssertEqual(AlbumDetailFeature.sortedAscending(items).map(\.id), ["a", "b", "c"])
    }

    func testCheckInStreakSkipsTodayWhenNotChecked() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let now = date("2026-10-16", calendar: calendar)
        let stats = HomeStats.checkIn(
            dates: ["2026-10-15", "2026-10-14", "2026-10-01"],
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(stats.continuousDays, 2)
        XCTAssertEqual(stats.monthDays, 3)
        XCTAssertEqual(stats.totalDays, 3)
        XCTAssertFalse(stats.checkedInToday)
        XCTAssertEqual(stats.recent.map(\.label), ["六", "日", "一", "二", "三", "四", "五"])
        XCTAssertEqual(stats.recent.last?.checked, false)
        XCTAssertEqual(stats.recent.dropLast().last?.checked, true)
    }

    func testStudyDurationBuckets() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let now = date("2026-10-16", calendar: calendar)
        let stats = HomeStats.study(
            durations: [
                "2026-10-16": 10 * 60 * 1000,
                "2026-10-13": 2 * 60 * 1000
            ],
            completed: 1,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(stats.totalParts.0, "12")
        XCTAssertEqual(stats.totalParts.1, "分钟")
        XCTAssertEqual(stats.todayText, "10分钟")
        XCTAssertEqual(stats.weekText, "12分钟")
        XCTAssertEqual(stats.monthText, "12分钟")
        XCTAssertEqual(stats.completedLessons, 1)
        XCTAssertEqual(stats.bars.last?.milliseconds, 10 * 60 * 1000)
    }

    @MainActor
    func testLockedEpisodeShowsPurchasePromptAndTrialPlays() async {
        let played = LockIsolated<[String]>([])
        var state = AlbumDetailFeature.State(album: Album(id: "s", name: "专辑", imageUrl: nil))
        state.items = [
            SutraItem(id: "trial", lesson: 1, isTrial: 1),
            SutraItem(id: "paid", lesson: 2)
        ]
        state.purchase = AlbumPurchase(isPaid: true, isPurchased: false, paidUrl: nil)
        let store = TestStore(initialState: state) {
            AlbumDetailFeature()
        } withDependencies: {
            $0.playback.play = { tracks, index, _, _ in played.withValue { $0.append(tracks[index].id) } }
        }
        await store.send(.trackTapped(state.items[1])) {
            $0.isPurchasePromptPresented = true
        }
        await store.send(.trackTapped(state.items[0]))
        XCTAssertEqual(played.value, ["trial"])
    }

    @MainActor
    func testPurchaseRefreshAnnouncesSuccess() async {
        var state = AlbumDetailFeature.State(album: Album(id: "s", name: "专辑", imageUrl: nil))
        state.purchase = AlbumPurchase(isPaid: true, isPurchased: false, paidUrl: nil)
        let store = TestStore(initialState: state) { AlbumDetailFeature() }
        await store.send(.purchaseLoaded(AlbumPurchase(isPaid: true, isPurchased: true, paidUrl: nil), announce: true)) {
            $0.purchase = AlbumPurchase(isPaid: true, isPurchased: true, paidUrl: nil)
            $0.toast = "购买成功，感谢您的支持！"
        }
    }

    @MainActor
    func testBoundPhoneUpdatesProfileAndUserInfo() async {
        var state = ProfileFeature.State()
        state.path.append(.userInfo(UserInfoFeature.State(profile: UserProfile())))
        state.path.append(.bindPhone(BindPhoneFeature.State()))
        let store = TestStore(initialState: state) { ProfileFeature() }
        store.exhaustivity = .off
        await store.send(.path(.element(id: state.path.ids.last!, action: .bindPhone(.delegate(.bound("13800000000"))))))
        XCTAssertEqual(store.state.profile.mobile, "13800000000")
        guard case let .userInfo(info) = store.state.path[id: state.path.ids.first!] else {
            return XCTFail("expected user info on the stack")
        }
        XCTAssertEqual(info.profile.mobile, "13800000000")
    }

    func testCheckInStorageMatchesAndroidAndIsJSONEncoded() throws {
        let profile = UserProfile(nickname: "张'三", avatar: "https://a/b.png", sex: 2, province: "上海", city: "浦东")
        let storage = CheckInPage.storage(unionid: "u1", profile: profile)
        XCTAssertEqual(storage["unionid"], "u1")
        XCTAssertEqual(storage["htz_gender"], "2")
        XCTAssertTrue(CheckInPage.storage(unionid: "", profile: profile).isEmpty)

        let script = try XCTUnwrap(HTZWebView.storageScript(["unionid": "u1", "htz_nickname": "张'三"]))
        XCTAssertTrue(script.contains(#"localStorage.setItem("unionid", JSON.stringify("u1"));"#))
        XCTAssertTrue(script.contains(#"JSON.stringify("张'三")"#))
    }

    func testAlbumPriceIsStoredInFen() {
        let album = Album(id: "s", name: "专辑", imageUrl: nil, isPaid: true, price: 9900)
        XCTAssertEqual(AlbumDetailFeature.State(album: album).price, 99)
    }

    func testSearchHitStartSeconds() {
        let hit = { (time: String) in
            SearchHit(id: "1", sutraTitle: "", title: "", time: time, content: "", lrcType: "")
        }
        XCTAssertEqual(hit("[01:30.50]").startSeconds, 90.5)
        XCTAssertEqual(hit("1:02:03").startSeconds, 3723)
        XCTAssertEqual(hit("").startSeconds, 0)
    }

    private func date(_ text: String, calendar: Calendar) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)!
    }
}
