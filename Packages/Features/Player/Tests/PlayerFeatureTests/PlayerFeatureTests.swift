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

        await store.send(.playQueue(tracks: tracks, startIndex: 0))
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
        ], startIndex: 0))
        await store.skipReceivedActions()
        await store.send(.playerStateUpdated(PlayerState(
            currentItem: PlayerItem(id: "a", url: audio, title: "甲", artist: nil, imageUrl: nil),
            currentTime: 10,
            duration: 10,
            didFinish: true
        )))
        await store.receive(\.nextTrack)
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
        ], startIndex: 0))
        await store.skipReceivedActions()
        await store.send(.nextTrack)
        await store.receive(\.playbackDenied)
        XCTAssertEqual(store.state.index, 0)
        XCTAssertEqual(store.state.alertMessage, "该内容为付费专栏，请订阅后收听。")
    }

    func testLyricParser() {
        let lines = LyricParser.parse("[00:01.50]第一句\n[00:03]第二句\n")
        XCTAssertEqual(lines.map(\.text), ["第一句", "第二句"])
        XCTAssertEqual(lines[0].millisecond, 1500)
        XCTAssertEqual(lines[1].millisecond, 3000)
    }
}

private final class PlayedBox: @unchecked Sendable {
    var items: [PlayerItem] = []
}
