import XCTest
@testable import NetworkKit

final class LocalHistoryTests: XCTestCase {
    private func makeStore(clock: LockBox) -> LocalHistory {
        LocalHistory(fileURL: nil, now: { clock.value })
    }

    final class LockBox: @unchecked Sendable { var value = 1_000 }

    private func server(_ id: String, at time: Int, position: Int = 5) -> ListenHistoryItem {
        ListenHistoryItem(id: "srv-\(id)", sutraItemId: id, sutraId: "s", title: "T\(id)", sutraName: "专辑", cover: "", lastPosition: position, createdAt: time)
    }

    func testPendingPlayShowsAtTopBeforeServerHasIt() {
        let clock = LockBox()
        let store = makeStore(clock: clock)
        store.remember(itemId: "b", sutraId: "s", title: "乙", sutraName: "专辑")
        clock.value = 2_000
        XCTAssertNotNil(store.record(itemId: "b", position: 30))

        let merged = store.merged(with: [server("a", at: 1_500)])
        XCTAssertEqual(merged.map(\.itemId), ["b", "a"])
        XCTAssertEqual(merged.first?.title, "乙")
        XCTAssertEqual(merged.first?.lastPosition, 30)
    }

    func testPendingPlayOverridesOlderServerRowAndKeepsItsId() {
        let clock = LockBox()
        let store = makeStore(clock: clock)
        store.remember(itemId: "a", sutraId: "s", title: "Ta", sutraName: "专辑")
        clock.value = 3_000
        store.record(itemId: "a", position: 99)

        let merged = store.merged(with: [server("a", at: 1_000, position: 5), server("b", at: 2_000)])
        XCTAssertEqual(merged.map(\.itemId), ["a", "b"])
        XCTAssertEqual(merged.first?.lastPosition, 99)
        XCTAssertEqual(merged.first?.id, "srv-a")
    }

    func testServerRowNewerThanPendingWinsAndSyncedPlayIsDropped() {
        let clock = LockBox()
        let store = makeStore(clock: clock)
        store.remember(itemId: "a", sutraId: "s", title: "Ta", sutraName: "专辑")
        clock.value = 2_000
        let stamp = store.record(itemId: "a", position: 10)!

        XCTAssertEqual(store.merged(with: [server("a", at: 2_500, position: 77)]).first?.lastPosition, 77)

        // Accepted by the server but not listed yet: still shown, so the play never disappears.
        store.markSynced(itemId: "a", upTo: stamp)
        XCTAssertEqual(store.merged(with: []).map(\.itemId), ["a"])
        XCTAssertTrue(store.stalePending(olderThan: 0).isEmpty)

        // Once a server list has it, the local copy is dropped.
        store.storeServerRows([server("a", at: 2_100)])
        XCTAssertEqual(store.merged(with: []).count, 0)
    }

    func testPendingPlaysSortAboveServerRowsEvenWithAheadServerClock() {
        let clock = LockBox()
        let store = makeStore(clock: clock)
        store.remember(itemId: "new", sutraId: "s", title: "新", sutraName: "专辑")
        clock.value = 1_000
        store.record(itemId: "new", position: 1)

        // The server clock is hours ahead of the device clock.
        let merged = store.merged(with: [server("a", at: 40_000), server("b", at: 39_000)])
        XCTAssertEqual(merged.map(\.itemId), ["new", "a", "b"])
    }

    func testUnknownEpisodeIsNotRecordedAndDeleteClearsPending() {
        let clock = LockBox()
        let store = makeStore(clock: clock)
        XCTAssertNil(store.record(itemId: "ghost", position: 1))

        store.remember(itemId: "a", sutraId: "s", title: "Ta", sutraName: "专辑")
        store.record(itemId: "a", position: 1)
        store.remove(id: "a")
        XCTAssertTrue(store.merged(with: []).isEmpty)
    }

    func testCachedRowsServeOfflineList() {
        let store = makeStore(clock: LockBox())
        store.storeServerRows([server("a", at: 10), server("b", at: 20)])
        XCTAssertEqual(store.cachedRows().map(\.itemId), ["a", "b"])
    }
}
