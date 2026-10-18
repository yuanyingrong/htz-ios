import XCTest
import ComposableArchitecture
import NetworkKit
@testable import Home

@MainActor
final class HistoryFeatureTests: XCTestCase {
    private func record(_ id: String, item: String, position: Int) -> ListenHistoryItem {
        ListenHistoryItem(id: id, sutraItemId: item, sutraId: "s", title: "第\(item)集", sutraName: "A", cover: "", lastPosition: position)
    }

    func testSameLessonIsShownOnceKeepingTheNewestRecord() {
        var state = HistoryFeature.State()
        state.records = [record("1", item: "a", position: 90), record("2", item: "b", position: 5), record("3", item: "a", position: 10)]
        XCTAssertEqual(state.items.map(\.id), ["1", "2"])
        XCTAssertEqual(state.items.first?.lastPosition, 90)
    }

    func testDeletingAggregatedRowRemovesEveryRecordOfTheLesson() async {
        let deleted = LockIsolated<[String]>([])
        var state = HistoryFeature.State()
        state.records = [record("1", item: "a", position: 90), record("2", item: "b", position: 5), record("3", item: "a", position: 10)]
        let store = TestStore(initialState: state) {
            HistoryFeature()
        } withDependencies: {
            $0.library.deleteHistory = { id in deleted.withValue { $0.append(id) } }
        }
        await store.send(.delete(state.items[0]))
        await store.receive(.deleted("a")) { $0.records = [state.records[1]] }
        XCTAssertEqual(deleted.value, ["1", "3"])
    }
}

extension HistoryFeatureTests {
    func testAggregationKeepsOrderAndFirstRecord() {
        let rows = [
            ListenHistoryItem(id: "1", sutraItemId: "a", sutraId: "s", title: "", sutraName: "", cover: "", lastPosition: 1),
            ListenHistoryItem(id: "2", sutraItemId: "a", sutraId: "s", title: "", sutraName: "", cover: "", lastPosition: 2),
            ListenHistoryItem(id: "3", sutraItemId: "b", sutraId: "s", title: "", sutraName: "", cover: "", lastPosition: 3),
        ]
        XCTAssertEqual(rows.aggregatedByLesson.map(\.id), ["1", "3"])
    }
}

extension HistoryFeatureTests {
    func testPlayingHistoryQueuesTheWholeAlbumAtThatLesson() async {
        let played = LockIsolated<(ids: [String], index: Int, position: Double)?>(nil)
        let history = ListenHistoryItem(id: "h", sutraItemId: "b", sutraId: "s", title: "第2集", sutraName: "A", cover: "", lastPosition: 42)
        let store = TestStore(initialState: HistoryFeature.State()) {
            HistoryFeature()
        } withDependencies: {
            $0.library.items = { _ in
                [SutraItem(id: "c", sutraId: "s", title: "第3集", lesson: 3), SutraItem(id: "a", sutraId: "s", title: "第1集", lesson: 1), SutraItem(id: "b", sutraId: "s", title: "第2集", lesson: 2)]
            }
            $0.playback.play = { tracks, index, _, position in
                played.setValue((tracks.map(\.id), index, position))
            }
        }
        await store.send(.play(history))
        await store.finish()
        XCTAssertEqual(played.value?.ids, ["a", "b", "c"])
        XCTAssertEqual(played.value?.index, 1)
        XCTAssertEqual(played.value?.position, 42)
    }
}

extension HistoryFeatureTests {
    func testHistoryPageRefreshesWhenPlaybackWritesHistory() async {
        let calls = LockIsolated(0)
        let store = TestStore(initialState: HistoryFeature.State()) {
            HistoryFeature()
        } withDependencies: {
            $0.library.histories = {
                calls.withValue { $0 += 1 }
                return []
            }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.skipReceivedActions()
        XCTAssertEqual(calls.value, 1)

        // Give the notification subscription a moment to start, then simulate a history write.
        try? await Task.sleep(nanoseconds: 100_000_000)
        NotificationCenter.default.post(name: .htzHistoryDidChange, object: nil)
        try? await Task.sleep(nanoseconds: 200_000_000)
        await store.skipReceivedActions()
        XCTAssertEqual(calls.value, 2)

        await store.skipInFlightEffects()
    }
}
