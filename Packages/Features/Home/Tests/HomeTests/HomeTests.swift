import XCTest
@testable import Home

final class HomeTests: XCTestCase {
    func testPackageLoads() {
        XCTAssertNotNil(HomeFeature.State())
    }

    func testCheckInStreakSkipsTodayWhenNotChecked() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let now = date("2026-10-16", calendar: calendar)
        let stats = HomeStats.checkIn(
            dates: ["2026-10-15", "2026-10-14", "2026-10-01"],
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(stats.continuousDays, 2)
        XCTAssertEqual(stats.monthDays, 3)
        XCTAssertEqual(stats.totalDays, 3)
        XCTAssertFalse(stats.checkedInToday)
        XCTAssertEqual(stats.recent.map(\.label), ["六", "日", "一", "二", "三", "四", "五"])
        XCTAssertEqual(stats.recent.last?.checked, false)
        XCTAssertEqual(stats.recent.dropLast().last?.checked, true)
    }

    func testStudyDurationBuckets() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let now = date("2026-10-16", calendar: calendar)
        let stats = HomeStats.study(
            durations: [
                "2026-10-16": 10 * 60 * 1000,
                "2026-10-13": 2 * 60 * 1000
            ],
            completed: 1,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(stats.totalParts.0, "12")
        XCTAssertEqual(stats.totalParts.1, "分钟")
        XCTAssertEqual(stats.todayText, "10分钟")
        XCTAssertEqual(stats.weekText, "12分钟")
        XCTAssertEqual(stats.monthText, "12分钟")
        XCTAssertEqual(stats.completedLessons, 1)
        XCTAssertEqual(stats.bars.last?.milliseconds, 10 * 60 * 1000)
    }

    private func date(_ text: String, calendar: Calendar) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)!
    }
}
