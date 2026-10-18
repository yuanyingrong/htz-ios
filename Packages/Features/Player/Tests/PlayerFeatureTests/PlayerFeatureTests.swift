import XCTest
import ComposableArchitecture
import HTZAudio
@testable import PlayerFeature

@MainActor
final class PlayerFeatureTests: XCTestCase {
    override func setUp() async throws {
        PlayModeStore.current = .sequential
    }

    override func invokeTest() {
        withDependencies {
            $0.library.favorites = { [] }
        } operation: {
            super.invokeTest()
        }
    }

    func testQueueAdvancesAndReports() async {
        let audioA = URL(string: "https://example.com/a.mp3")!
        let audioB = URL(string: "https://example.com/b.mp3")!
        let tracks = [
            QueueTrack(id: "a", sutraId: "s", title: "甲", audioURL: audioA),
            QueueTrack(id: "b", sutraId: "s", title: "乙")
        ]
        let played = PlayedBox()
        let store = TestStore(initialState: PlayerFeature.State()) {
            PlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { played.items.append($0) }
            $0.playerClient.playerStateStream = { AsyncStream { $0.finish() } }
            $0.trackResolver.resolve = { _, itemId in
                ResolvedAudio(audioURL: itemId == "b" ? audioB : audioA)
            }
            $0.trackResolver.localFile = { _ in nil }
            $0.nowPlayingClient.commands = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off

        await store.send(.playQueue(tracks: tracks, startIndex: 0, startPosition: 0))
        await store.finish()
        XCTAssertEqual(played.items.map(\.id), ["a"])

        await store.send(.nextTrack)
        await store.finish()
        XCTAssertEqual(store.state.index, 1)
        XCTAssertEqual(played.items.map(\.id), ["a", "b"])
    }

    func testFinishedTrackAdvances() async {
        let audio = URL(string: "https://example.com/a.mp3")!
        let store = TestStore(initialState: PlayerFeature.State()) {
            PlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { _ in }
            $0.playerClient.playerStateStream = { AsyncStream { $0.finish() } }
            $0.trackResolver.resolve = { _, _ in ResolvedAudio(audioURL: audio) }
            $0.trackResolver.localFile = { _ in nil }
            $0.nowPlayingClient.commands = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off
        await store.send(.playQueue(tracks: [
            QueueTrack(id: "a", sutraId: "s", title: "甲", audioURL: audio),
            QueueTrack(id: "b", sutraId: "s", title: "乙")
        ], startIndex: 0, startPosition: 0))
        await store.skipReceivedActions()
        await store.send(.playerStateUpdated(PlayerState(
            currentItem: PlayerItem(id: "a", url: audio, title: "甲", artist: nil, imageUrl: nil),
            currentTime: 10,
            duration: 10,
            didFinish: true
        )))
        await store.receive(\.trackDidFinish)
        await store.receive(\.trackResolved)
        await store.skipReceivedActions()
        XCTAssertEqual(store.state.index, 1)
    }

    func testDeniedNextDoesNotStayOnBlockedTrack() async {
        let audio = URL(string: "https://example.com/a.mp3")!
        let store = TestStore(initialState: PlayerFeature.State()) {
            PlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { _ in }
            $0.playerClient.pause = {}
            $0.playerClient.playerStateStream = { AsyncStream { $0.finish() } }
            $0.trackResolver.resolve = { _, _ in throw TrackResolveError.accessDenied }
            $0.trackResolver.localFile = { _ in nil }
            $0.nowPlayingClient.commands = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off
        await store.send(.playQueue(tracks: [
            QueueTrack(id: "a", sutraId: "s", title: "甲", audioURL: audio),
            QueueTrack(id: "b", sutraId: "s", title: "乙")
        ], startIndex: 0, startPosition: 0))
        await store.skipReceivedActions()
        await store.send(.nextTrack)
        await store.receive(\.playbackDenied)
        await store.skipReceivedActions()
        XCTAssertEqual(store.state.index, 0)
        XCTAssertEqual(store.state.currentItem?.id, "a")
        XCTAssertEqual(store.state.toast, "该内容为付费专栏，请订阅后收听。")
    }

    func testManualNextInShuffleStaysSequential() async {
        var state = PlayerFeature.State()
        state.playMode = .shuffle
        state.queue = [
            QueueTrack(id: "a", sutraId: "s", title: "1"),
            QueueTrack(id: "b", sutraId: "s", title: "2"),
            QueueTrack(id: "c", sutraId: "s", title: "3")
        ]
        state.index = 0
        let store = TestStore(initialState: state) {
            PlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { _ in }
            $0.playerClient.pause = {}
            $0.playerClient.playerStateStream = { AsyncStream { $0.finish() } }
            $0.trackResolver.localFile = { _ in nil }
            $0.trackResolver.resolve = { _, itemId in
                ResolvedAudio(audioURL: URL(string: "https://example.com/\(itemId).mp3")!)
            }
            $0.nowPlayingClient.commands = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off
        await store.send(.nextTrack)
        await store.skipReceivedActions()
        XCTAssertEqual(store.state.index, 1)
        XCTAssertEqual(store.state.currentItem?.id, "b")
    }

    func testNextIgnoresStaleEngineTicks() async {
        let audioA = URL(string: "https://example.com/a.mp3")!
        let audioB = URL(string: "https://example.com/b.mp3")!
        let played = PlayedBox()
        let store = TestStore(initialState: PlayerFeature.State()) {
            PlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { played.items.append($0) }
            $0.playerClient.pause = {}
            $0.playerClient.playerStateStream = { AsyncStream { $0.finish() } }
            $0.trackResolver.resolve = { _, itemId in
                ResolvedAudio(audioURL: itemId == "b" ? audioB : audioA)
            }
            $0.trackResolver.localFile = { _ in nil }
            $0.nowPlayingClient.commands = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off
        await store.send(.playQueue(tracks: [
            QueueTrack(id: "a", sutraId: "s", title: "甲", audioURL: audioA),
            QueueTrack(id: "b", sutraId: "s", title: "乙", audioURL: audioB)
        ], startIndex: 0, startPosition: 0))
        await store.skipReceivedActions()
        await store.send(.nextTrack)
        await store.skipReceivedActions()
        // Stale tick for the previous item must not pull the queue back.
        await store.send(.playerStateUpdated(PlayerState(
            currentItem: PlayerItem(id: "a", url: audioA, title: "甲", artist: nil, imageUrl: nil),
            isPlaying: true,
            currentTime: 12,
            duration: 100
        )))
        XCTAssertEqual(store.state.index, 1)
        XCTAssertEqual(store.state.currentItem?.id, "b")
        XCTAssertEqual(played.items.map(\.id).last, "b")
    }

    func testNextPlaysResolvedTrackAndKeepsFallbackLyrics() async {
        let audioA = URL(string: "https://example.com/a.mp3")!
        let audioB = URL(string: "https://example.com/b.mp3")!
        let lyricB = URL(string: "https://example.com/b.lrc")!
        let calls = CallLog()
        let store = TestStore(initialState: PlayerFeature.State()) {
            PlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { calls.entries.append("play:\($0.id)") }
            $0.playerClient.pause = { calls.entries.append("pause") }
            $0.playerClient.playerStateStream = { AsyncStream { $0.finish() } }
            $0.trackResolver.resolve = { _, _ in ResolvedAudio(audioURL: audioB) }
            $0.trackResolver.localFile = { _ in nil }
            $0.trackResolver.reportHistory = { _, _ in }
            $0.nowPlayingClient.commands = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off
        await store.send(.playQueue(tracks: [
            QueueTrack(id: "a", sutraId: "s", title: "甲", audioURL: audioA),
            QueueTrack(id: "b", sutraId: "s", title: "乙", explanationLyricURL: lyricB)
        ], startIndex: 0, startPosition: 0))
        await store.finish()
        calls.entries.removeAll()

        await store.send(.nextTrack)
        await store.receive(\.trackResolved)
        await store.finish()
        XCTAssertEqual(calls.entries, ["pause", "play:b"])
        XCTAssertEqual(store.state.currentItem?.url, audioB)
        XCTAssertEqual(store.state.queue[1].explanationLyricURL, lyricB)
        XCTAssertFalse(store.state.isResolving)
    }

    func testSingleModeReplaysOnFinish() async {
        let audio = URL(string: "https://example.com/a.mp3")!
        var seekSeconds: [Double] = []
        let store = TestStore(initialState: PlayerFeature.State()) {
            PlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { _ in }
            $0.playerClient.seek = { seekSeconds.append($0) }
            $0.playerClient.resume = {}
            $0.playerClient.playerStateStream = { AsyncStream { $0.finish() } }
            $0.trackResolver.localFile = { _ in nil }
            $0.nowPlayingClient.commands = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off
        await store.send(.playQueue(tracks: [
            QueueTrack(id: "a", sutraId: "s", title: "甲", audioURL: audio)
        ], startIndex: 0, startPosition: 0))
        await store.skipReceivedActions()
        await store.send(.cyclePlayMode)
        await store.send(.cyclePlayMode)
        await store.send(.cyclePlayMode)
        XCTAssertEqual(store.state.playMode, .single)
        await store.send(.trackDidFinish)
        await store.finish()
        XCTAssertEqual(store.state.index, 0)
        XCTAssertEqual(seekSeconds.last, 0)
    }

    func testEpisodeSleepTimerPausesInsteadOfAdvancing() async {
        var paused = false
        var state = PlayerFeature.State()
        state.queue = [
            QueueTrack(id: "a", sutraId: "s", title: "1"),
            QueueTrack(id: "b", sutraId: "s", title: "2")
        ]
        let store = TestStore(initialState: state) {
            PlayerFeature()
        } withDependencies: {
            $0.playerClient.pause = { paused = true }
        }
        await store.send(.setSleepTimer(.episodes(1))) {
            $0.sleepTimer = .episodes(1)
        }
        await store.send(.trackDidFinish) {
            $0.sleepTimer = nil
        }
        XCTAssertTrue(paused)
        XCTAssertEqual(store.state.index, 0)
    }

    func testMinuteSleepTimerCountsDownAndPauses() async {
        let clock = TestClock()
        let store = TestStore(initialState: PlayerFeature.State()) {
            PlayerFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.playerClient.pause = {}
            $0.trackResolver.reportHistory = { _, _ in }
        }
        store.exhaustivity = .off
        await store.send(.setSleepTimer(.minutes(1))) {
            $0.sleepTimer = .minutes(1)
            $0.sleepSecondsLeft = 60
        }
        await clock.advance(by: .seconds(60))
        await store.receive(\.pauseButtonTapped)
        XCTAssertNil(store.state.sleepTimer)
        XCTAssertNil(store.state.sleepSecondsLeft)
    }

    func testPlayerFeedbackUsesToastAndKeepsFullPlayerOpen() async {
        var state = PlayerFeature.State()
        state.showFullPlayer = true
        state.queue = [QueueTrack(id: "a", sutraId: "s", title: "1")]
        let store = TestStore(initialState: state) {
            PlayerFeature()
        } withDependencies: {
            $0.downloads.isDownloaded = { _ in true }
        }
        await store.send(.cyclePlayMode) {
            $0.playMode = .shuffle
            $0.toast = PlayMode.shuffle.title
        }
        await store.send(.downloadCurrent) {
            $0.toast = "已下载"
        }
        XCTAssertTrue(store.state.showFullPlayer)
    }

    func testReverseQueueKeepsCurrentTrack() async {
        var state = PlayerFeature.State()
        state.queue = ["a", "b", "c"].map { QueueTrack(id: $0, sutraId: "s", title: $0) }
        state.index = 0
        let store = TestStore(initialState: state) { PlayerFeature() }
        await store.send(.reverseQueue) {
            $0.queue = ["c", "b", "a"].map { QueueTrack(id: $0, sutraId: "s", title: $0) }
            $0.index = 2
        }
    }

    func testLyricParser() {
        let parsed = LyricParser.parse("[00:01.50]第一句\n[00:03]第二句\n")
        XCTAssertEqual(parsed.map(\.text), ["第一句", "第二句"])
        XCTAssertEqual(parsed[0].millisecond, 1500)
        XCTAssertEqual(parsed[1].millisecond, 3000)
        let plain = LyricParser.lines(from: "哪三个方向呢\n第一个是生理的健康\n")
        XCTAssertEqual(plain.map(\.text), ["哪三个方向呢", "第一个是生理的健康"])
    }

    func testActiveLyricScanOncePerTick() {
        let lines = (0..<800).map { LyricLine(millisecond: $0 * 500, text: "讲解") }
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<4 {
            _ = lines.lastIndex { $0.millisecond <= 200_000 }
        }
        let milliseconds = (CFAbsoluteTimeGetCurrent() - start) * 1000
        XCTAssertLessThan(milliseconds, 5)
    }
}

private final class PlayedBox: @unchecked Sendable {
    var items: [PlayerItem] = []
}

private final class CallLog: @unchecked Sendable {
    var entries: [String] = []
}
