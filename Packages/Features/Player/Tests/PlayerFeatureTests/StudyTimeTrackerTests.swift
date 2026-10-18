import XCTest
@testable import PlayerFeature

final class StudyTimeTrackerTests: XCTestCase {
    private final class Clock: @unchecked Sendable {
        var time: TimeInterval = 100
    }

    private func makeTracker(clock: Clock, user: String? = "u1") -> StudyTimeTracker {
        let suite = "study-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return StudyTimeTracker(defaults: defaults, now: { clock.time }, userId: { user }, reportInterval: 60)
    }

    func testCountsOnlyWhilePlayingAndIgnoresGaps() {
        let clock = Clock()
        let tracker = makeTracker(clock: clock)
        _ = tracker.tick(isPlaying: true)
        clock.time += 1
        _ = tracker.tick(isPlaying: true)
        clock.time += 1
        _ = tracker.tick(isPlaying: true)
        // Paused for a long time: nothing accrues.
        clock.time += 30
        _ = tracker.tick(isPlaying: false)
        clock.time += 30
        _ = tracker.tick(isPlaying: false)
        // A long gap while "playing" (e.g. app suspended) is not counted either.
        clock.time += 10
        _ = tracker.tick(isPlaying: true)
        XCTAssertEqual(tracker.totals().values.reduce(0, +), 2000)
    }

    func testReportDueOnPauseAndEveryInterval() {
        let clock = Clock()
        let tracker = makeTracker(clock: clock)
        XCTAssertEqual(tracker.tick(isPlaying: true), .due) // first tick, never reported
        clock.time += 1
        XCTAssertEqual(tracker.tick(isPlaying: true), .none)
        clock.time += 61
        XCTAssertEqual(tracker.tick(isPlaying: true), .due)
        clock.time += 1
        XCTAssertEqual(tracker.tick(isPlaying: false), .due) // paused
        clock.time += 1
        XCTAssertEqual(tracker.tick(isPlaying: false), .none)
    }

    func testNoAccountMeansNoTracking() {
        let clock = Clock()
        let tracker = makeTracker(clock: clock, user: nil)
        _ = tracker.tick(isPlaying: true)
        clock.time += 1
        _ = tracker.tick(isPlaying: true)
        XCTAssertTrue(tracker.totals().isEmpty)
    }
}
