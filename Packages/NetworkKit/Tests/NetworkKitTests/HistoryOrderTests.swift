import XCTest
@testable import NetworkKit

final class HistoryOrderTests: XCTestCase {
    private func item(_ id: String, _ time: Int) -> ListenHistoryItem {
        ListenHistoryItem(id: id, sutraItemId: id, sutraId: "s", title: id, sutraName: "A", cover: "", lastPosition: 0, createdAt: time)
    }

    func testSortsNewestFirstAndKeepsServerOrderForTies() {
        let rows = [item("old", 100), item("none1", 0), item("new", 300), item("none2", 0), item("mid", 200)]
        XCTAssertEqual(rows.sortedNewestFirst().map(\.id), ["new", "mid", "old", "none1", "none2"])
    }

    func testEpochSecondsAcceptsSecondsMillisAndStrings() {
        XCTAssertEqual(LibraryAPI.epochSeconds(["created_at": 1_700_000_000], "created_at"), 1_700_000_000)
        XCTAssertEqual(LibraryAPI.epochSeconds(["created_at": 1_700_000_000_000], "created_at"), 1_700_000_000)
        XCTAssertEqual(LibraryAPI.epochSeconds(["created_at": "1700000000"], "created_at"), 1_700_000_000)
        XCTAssertEqual(LibraryAPI.epochSeconds([:], "created_at"), 0)
    }
}
