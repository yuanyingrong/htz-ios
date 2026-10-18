import XCTest
import ComposableArchitecture
import PlayerFeature
@testable import Home

@MainActor
final class DownloadsFeatureTests: XCTestCase {
    private func record(_ id: String, album: String = "A", lesson: Int) -> DownloadRecord {
        DownloadRecord(id: id, title: "第\(lesson)集", sutraId: album, albumName: album, lesson: lesson, state: .finished)
    }

    private func makeState() -> DownloadsFeature.State {
        var state = DownloadsFeature.State()
        // Deliberately out of order: groups must come back sorted by lesson.
        state.records = [record("a3", lesson: 3), record("a1", lesson: 1), record("b1", album: "B", lesson: 1)]
        return state
    }

    func testAlbumsAreSortedByLessonAndCollapsedByDefault() {
        let state = makeState()
        XCTAssertEqual(state.albums.first?.items.map(\.id), ["a1", "a3"])
        XCTAssertTrue(state.expanded.isEmpty)
    }

    func testSelectingAlbumTogglesAllItems() async {
        let store = TestStore(initialState: makeState()) { DownloadsFeature() }
        let group = store.state.albums[0]
        await store.send(.toggleGroupSelection(group)) { $0.selection = ["a1", "a3"] }
        await store.send(.toggleGroupSelection(group)) { $0.selection = [] }
    }

    func testDeleteIsUndoableBeforeFilesAreRemoved() async {
        let deleted = LockIsolated<[[String]]>([])
        let clock = TestClock()
        let store = TestStore(initialState: makeState()) {
            DownloadsFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.downloads.delete = { ids in deleted.withValue { $0.append(ids.sorted()) } }
        }
        await store.send(.requestDelete(message: "m", ids: ["a1"])) {
            $0.confirm = .init(message: "m", ids: ["a1"])
            $0.isConfirmPresented = true
        }
        await store.send(.confirmDelete) {
            $0.confirm = nil
            $0.isConfirmPresented = false
            $0.hiddenIDs = ["a1"]
            $0.showUndo = true
            $0.$hidesBottomChrome.withLock { $0 = true }
        }
        XCTAssertEqual(store.state.finished.map(\.id), ["a3", "b1"])
        await store.send(.undoDelete) {
            $0.hiddenIDs = []
            $0.showUndo = false
            $0.$hidesBottomChrome.withLock { $0 = false }
        }
        await clock.advance(by: .seconds(10))
        XCTAssertTrue(deleted.value.isEmpty)
        XCTAssertEqual(store.state.finished.count, 3)
    }

    func testDeleteCommitsAfterUndoWindow() async {
        let deleted = LockIsolated<[[String]]>([])
        let clock = TestClock()
        let store = TestStore(initialState: makeState()) {
            DownloadsFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.downloads.delete = { ids in deleted.withValue { $0.append(ids.sorted()) } }
        }
        await store.send(.toggleSelection("a1")) { $0.selection = ["a1"] }
        await store.send(.toggleSelection("b1")) { $0.selection = ["a1", "b1"] }
        await store.send(.toggleEditing) {
            $0.isEditing = true
            $0.selection = []
            $0.$hidesBottomChrome.withLock { $0 = true }
        }
        await store.send(.toggleSelection("a1")) { $0.selection = ["a1"] }
        await store.send(.deleteSelected) {
            $0.isEditing = false
            $0.selection = []
            $0.hiddenIDs = ["a1"]
            $0.showUndo = true
        }
        await clock.advance(by: .seconds(4))
        await store.receive(\.commitDelete) {
            $0.hiddenIDs = []
            $0.showUndo = false
            $0.$hidesBottomChrome.withLock { $0 = false }
        }
        XCTAssertEqual(deleted.value, [["a1"]])
    }

    func testLeavingThePageCommitsPendingDelete() async {
        let deleted = LockIsolated<[[String]]>([])
        var state = makeState()
        state.hiddenIDs = ["a1"]
        state.showUndo = true
        let store = TestStore(initialState: state) {
            DownloadsFeature()
        } withDependencies: {
            $0.downloads.delete = { ids in deleted.withValue { $0.append(ids) } }
        }
        await store.send(.onDisappear) {
            $0.hiddenIDs = []
            $0.showUndo = false
        }
        XCTAssertEqual(deleted.value, [["a1"]])
    }
}
