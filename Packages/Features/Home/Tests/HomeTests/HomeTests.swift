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
    func testAlbumDetailStatePaintsCachedItemsWithoutWaiting() {
        let sutraId = "cache-\(UUID().uuidString)"
        ItemsCache.shared.set(
            [SutraItem(id: "1", title: "一", lesson: 1), SutraItem(id: "2", title: "二", lesson: 2)],
            for: sutraId
        )
        let state = AlbumDetailFeature.State(album: Album(id: sutraId, name: "缓存专辑", imageUrl: nil))
        XCTAssertEqual(state.items.map(\.id), ["1", "2"])
        XCTAssertFalse(state.isLoading)
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
    func testTappingEpisodeResumesFromSavedPosition() async {
        let started = LockIsolated<[(String, Double)]>([])
        var state = AlbumDetailFeature.State(album: Album(id: "s", name: "专辑", imageUrl: nil))
        let items = [
            SutraItem(id: "mid", lesson: 1, duration: 600_000),
            SutraItem(id: "almost", lesson: 2, duration: 600_000),
            SutraItem(id: "fresh", lesson: 3, duration: 600_000)
        ]
        state.items = items
        state.progress = ["mid": 120, "almost": 595]
        let store = TestStore(initialState: state) {
            AlbumDetailFeature()
        } withDependencies: {
            $0.playback.play = { tracks, index, _, position in
                started.withValue { $0.append((tracks[index].id, position)) }
            }
        }
        await store.send(.trackTapped(items[0]))
        await store.send(.trackTapped(items[1]))
        await store.send(.trackTapped(items[2]))
        XCTAssertEqual(started.value.map(\.0), ["mid", "almost", "fresh"])
        XCTAssertEqual(started.value.map(\.1), [120, 0, 0])
    }

    @MainActor
    func testFavoriteAndDownloadPlayContinueFromHistory() async {
        let started = LockIsolated<[(String, Double)]>([])
        let history = ListenHistoryItem(id: "h", sutraItemId: "a", sutraId: "s", title: "甲", sutraName: "专辑", cover: "", lastPosition: 120_000)

        var favorites = FavoritesFeature.State()
        let favorite = FavoriteItem(id: "f", serverId: "x", sutraItemId: "a", sutraId: "s", title: "甲", sutraName: "专辑", cover: "")
        favorites.items = [favorite]
        let favoritesStore = TestStore(initialState: favorites) {
            FavoritesFeature()
        } withDependencies: {
            $0.library.histories = { [history] }
            $0.playback.play = { tracks, index, _, position in
                started.withValue { $0.append((tracks[index].id, position)) }
            }
        }
        await favoritesStore.send(.play(favorite))
        await favoritesStore.finish()

        var downloads = DownloadsFeature.State()
        let record = DownloadRecord(id: "a", title: "甲", sutraId: "s", albumName: "专辑", state: .finished)
        downloads.records = [record]
        let downloadsStore = TestStore(initialState: downloads) {
            DownloadsFeature()
        } withDependencies: {
            $0.library.histories = { [history] }
            $0.playback.play = { tracks, index, _, position in
                started.withValue { $0.append((tracks[index].id, position)) }
            }
        }
        await downloadsStore.send(.play(record))
        await downloadsStore.finish()

        XCTAssertEqual(started.value.map(\.0), ["a", "a"])
        XCTAssertEqual(started.value.map(\.1), [120, 120])
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
