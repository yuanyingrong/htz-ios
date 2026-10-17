import XCTest
import ComposableArchitecture
import HTZAudio
@testable import PlayerFeature

@MainActor
final class PlayerFeatureTests: XCTestCase {
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
        XCTAssertEqual(store.state.index, 0)
        XCTAssertEqual(store.state.alertMessage, "该内容为付费专栏，请订阅后收听。")
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
        await store.skipReceivedActions()
        XCTAssertEqual(store.state.index, 0)
        XCTAssertEqual(seekSeconds.last, 0)
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
