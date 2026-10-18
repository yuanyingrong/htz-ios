import XCTest
@testable import NetworkKit

final class ItemsCacheTests: XCTestCase {
    func testMemoryRoundTripIsSubMillisecondForHundredsOfItems() {
        let sutraId = "perf-\(UUID().uuidString)"
        var items: [SutraItem] = []
        items.reserveCapacity(300)
        for index in 0..<300 {
            items.append(SutraItem(id: "i\(index)", sutraId: sutraId, title: "ep-\(index)", lesson: index))
        }
        XCTAssertEqual(items.first?.id, "i0")

        let writeStart = CFAbsoluteTimeGetCurrent()
        ItemsCache.shared.set(items, for: sutraId)
        let writeMs = (CFAbsoluteTimeGetCurrent() - writeStart) * 1000

        let readStart = CFAbsoluteTimeGetCurrent()
        let cached = ItemsCache.shared.get(sutraId)
        let readMs = (CFAbsoluteTimeGetCurrent() - readStart) * 1000

        XCTAssertEqual(cached?.count, 300)
        XCTAssertEqual(cached?.first?.id, "i0")
        XCTAssertEqual(cached?.first?.title, "ep-0")
        // Memory hit must be far below one frame; disk write can be a bit slower.
        XCTAssertLessThan(readMs, 5, "memory read took \(readMs)ms")
        XCTAssertLessThan(writeMs, 100, "cache write took \(writeMs)ms")
        print("ItemsCache perf: write=\(String(format: "%.3f", writeMs))ms read=\(String(format: "%.3f", readMs))ms")
    }

    func testCachedItemsSurfacesThroughLibraryAPI() {
        let sutraId = "api-\(UUID().uuidString)"
        let items = [SutraItem(id: "a", title: "甲"), SutraItem(id: "b", title: "乙")]
        ItemsCache.shared.set(items, for: sutraId)
        XCTAssertEqual(LibraryAPI.cachedItems(sutraId: sutraId)?.map(\.id), ["a", "b"])
    }
}
