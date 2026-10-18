import XCTest
import ComposableArchitecture
import NetworkKit
@testable import Home

@MainActor
final class SearchFeatureTests: XCTestCase {
    private func hit(_ album: String, _ title: String, id: String? = nil) -> SearchHit {
        SearchHit(id: id ?? "\(album)-\(title)", sutraTitle: album, title: title, time: "00:10", content: "内容", lrcType: "explanation")
    }

    // MARK: Highlight

    func testServerEmMarksAreHighlightedAndTagsStripped() {
        let segments = SearchHighlight.segments("前<em>金刚</em>后<b>x</b>", keyword: "其他")
        XCTAssertEqual(segments, [
            .init(text: "前", highlighted: false),
            .init(text: "金刚", highlighted: true),
            .init(text: "后x", highlighted: false),
        ])
    }

    func testKeywordIsHighlightedWhenNoServerMarks() {
        let segments = SearchHighlight.segments("黄庭经与黄庭禅", keyword: "黄庭")
        XCTAssertEqual(segments.map(\.text), ["黄庭", "经与", "黄庭", "禅"])
        XCTAssertEqual(segments.map(\.highlighted), [true, false, true, false])
    }

    // MARK: Filter options / visibility

    func testFilterOptionsAreSortedByHitCountAndFilterHidesAlbums() {
        var state = SearchFeature.State()
        state.hits = [hit("B", "1"), hit("A", "1"), hit("A", "2")]
        XCTAssertEqual(state.filterOptions, ["A", "B"])
        XCTAssertEqual(state.visibleHits.count, 3)

        state.filterAlbum = "B"
        XCTAssertEqual(state.visibleHits.map(\.title), ["1"])
        XCTAssertTrue(state.visibleAlbums.isEmpty)
        XCTAssertEqual(state.requestSize, SearchFeature.filterPageSize)
    }

    // MARK: Reducer

    func testTypingSearchesAfterDebounceAndShortQueryClears() async {
        let clock = TestClock()
        let calls = LockIsolated<[[Int]]>([])
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.library.search = { _, offset, limit in
                calls.withValue { $0.append([offset, limit]) }
                return offset == 0 ? [SearchHit(id: "1", sutraTitle: "A", title: "t", time: "00:01", content: "c", lrcType: "explanation")] : []
            }
        }
        store.exhaustivity = .off

        await store.send(.binding(.set(\.query, "金刚")))
        await clock.advance(by: .milliseconds(400))
        await store.skipReceivedActions()
        XCTAssertEqual(store.state.keyword, "金刚")
        XCTAssertEqual(store.state.hits.count, 1)
        XCTAssertFalse(store.state.hasMore)
        XCTAssertEqual(calls.value.first, [0, 20])

        await store.send(.binding(.set(\.query, "金")))
        XCTAssertEqual(store.state.keyword, "")
        XCTAssertTrue(store.state.hits.isEmpty)
    }

    func testSelectingAlbumFilterRestartsSearchWithLargePageAndAutoFills() async {
        let calls = LockIsolated<[[Int]]>([])
        var initial = SearchFeature.State()
        initial.keyword = "金刚"
        initial.query = "金刚"
        initial.hits = [hit("A", "1")]
        let store = TestStore(initialState: initial) {
            SearchFeature()
        } withDependencies: {
            $0.library.search = { _, offset, limit in
                calls.withValue { $0.append([offset, limit]) }
                // Only the second page contains the filtered album.
                switch offset {
                case 0: return [SearchHit(id: "x", sutraTitle: "A", title: "a", time: "00:01", content: "c", lrcType: "explanation")]
                case 100: return [SearchHit(id: "y", sutraTitle: "B", title: "b", time: "00:01", content: "c", lrcType: "explanation")]
                default: return []
                }
            }
        }
        store.exhaustivity = .off

        await store.send(.selectFilter("B"))
        await store.skipReceivedActions()

        XCTAssertEqual(store.state.filterAlbum, "B")
        XCTAssertEqual(calls.value.prefix(2).map { $0 }, [[0, 100], [100, 100]])
        XCTAssertEqual(store.state.visibleHits.map(\.title), ["b"])
    }

    func testShortSubmitShowsToastWithoutSearching() async {
        var initial = SearchFeature.State()
        initial.query = "金"
        let store = TestStore(initialState: initial) { SearchFeature() }
        await store.send(.submit) { $0.toast = "输入内容过短" }
    }
}
