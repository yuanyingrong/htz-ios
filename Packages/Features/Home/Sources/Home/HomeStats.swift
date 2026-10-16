import Foundation

public enum HomeStats {
    public struct Day: Equatable, Identifiable {
        var date: String
        var label: String
        var checked: Bool
        public var id: String { date }
    }

    public struct CheckIn: Equatable {
        var continuousDays = 0
        var monthDays = 0
        var totalDays = 0
        var checkedInToday = false
        var recent: [Day] = []
    }

    public struct Bar: Equatable, Identifiable {
        var label: String
        var milliseconds: Int
        public var id: String { label }
    }

    public struct Study: Equatable {
        var totalMilliseconds = 0
        var completedLessons = 0
        var todayText = "0秒"
        var weekText = "0秒"
        var monthText = "0秒"
        var bars: [Bar] = []

        var totalParts: (String, String) {
            HomeStats.splitDuration(totalMilliseconds)
        }
    }

    public static func checkIn(dates: Set<String>, now: Date = Date(), calendar: Calendar = .current) -> CheckIn {
        var stats = CheckIn()
        stats.totalDays = dates.count
        let today = dayKey(now, calendar: calendar)
        stats.checkedInToday = dates.contains(today)

        var recent: [Day] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let key = dayKey(date, calendar: calendar)
            recent.append(Day(date: key, label: weekLabel(date, calendar: calendar), checked: dates.contains(key)))
        }
        stats.recent = recent

        var cursor = now
        if !stats.checkedInToday {
            cursor = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }
        var streak = 0
        while dates.contains(dayKey(cursor, calendar: calendar)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
            if streak > 5000 { break }
        }
        stats.continuousDays = streak

        let monthPrefix = String(today.prefix(7))
        stats.monthDays = dates.filter { $0.hasPrefix(monthPrefix) }.count
        return stats
    }

    public static func study(durations: [String: Int], completed: Int, now: Date = Date(), calendar: Calendar = .current) -> Study {
        var stats = Study()
        stats.completedLessons = completed
        stats.totalMilliseconds = durations.values.reduce(0, +)
        let today = dayKey(now, calendar: calendar)
        stats.todayText = formatDuration(durations[today] ?? 0)

        var week = 0
        let weekday = calendar.component(.weekday, from: now)
        let sinceMonday = (weekday - 2 + 7) % 7
        if let monday = calendar.date(byAdding: .day, value: -sinceMonday, to: now) {
            for offset in 0...sinceMonday {
                if let date = calendar.date(byAdding: .day, value: offset, to: monday) {
                    week += durations[dayKey(date, calendar: calendar)] ?? 0
                }
            }
        }
        stats.weekText = formatDuration(week)

        var month = 0
        let day = calendar.component(.day, from: now)
        if let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) {
            for offset in 0..<day {
                if let date = calendar.date(byAdding: .day, value: offset, to: start) {
                    month += durations[dayKey(date, calendar: calendar)] ?? 0
                }
            }
        }
        stats.monthText = formatDuration(month)

        var bars: [Bar] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let key = dayKey(date, calendar: calendar)
            bars.append(Bar(label: weekLabel(date, calendar: calendar), milliseconds: durations[key] ?? 0))
        }
        stats.bars = bars
        return stats
    }

    static func splitDuration(_ milliseconds: Int) -> (String, String) {
        let minutes = milliseconds / 1000 / 60
        if minutes >= 60 {
            let hours = Double(minutes) / 60
            let value = hours >= 100 ? String(Int(hours.rounded())) : String(format: "%.1f", hours)
            return (value, "小时")
        }
        return (String(minutes), "分钟")
    }

    static func formatDuration(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let minutes = seconds / 60
        let hours = minutes / 60
        let remain = minutes % 60
        if hours > 0 { return "\(hours)小时\(remain)分钟" }
        if minutes > 0 { return "\(minutes)分钟" }
        return "\(seconds)秒"
    }

    static func load(unionid: String) async -> (CheckIn, Study) {
        guard !unionid.isEmpty else {
            return (checkIn(dates: []), study(durations: [:], completed: 0))
        }
        async let dates = checkInDates(userId: unionid)
        async let durations = studyDurations(userId: unionid)
        async let completed = completedCount(userId: unionid)
        return await (checkIn(dates: dates), study(durations: durations, completed: completed))
    }

    private static func checkInDates(userId: String) async -> Set<String> {
        let calendar = Calendar.current
        let start = await registerMonth(userId: userId, calendar: calendar)
            ?? calendar.date(byAdding: .month, value: -11, to: Date())
            ?? Date()
        let months = monthKeys(from: start, calendar: calendar)
        var dates = Set<String>()
        let chunk = 6
        var index = 0
        while index < months.count {
            let slice = Array(months[index..<min(index + chunk, months.count)])
            index += chunk
            await withTaskGroup(of: [String].self) { group in
                for month in slice {
                    group.addTask { await fetchMonth(userId: userId, month: month) }
                }
                for await monthDates in group {
                    dates.formUnion(monthDates)
                }
            }
        }
        return dates
    }

    private static func monthKeys(from start: Date, calendar: Calendar) -> [String] {
        var keys: [String] = []
        var cursor = calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start
        let end = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        while cursor <= end && keys.count < 120 {
            keys.append(monthKey(cursor, calendar: calendar))
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return keys
    }

    private static func registerMonth(userId: String, calendar: Calendar) async -> Date? {
        guard let data = await get(url(base: checkInHost, path: "getById", query: ["id": userId])),
              let json = try? JSONSerialization.jsonObject(with: data) else { return nil }
        let object = (json as? [String: Any])?["data"] as? [String: Any] ?? json as? [String: Any]
        guard let raw = object?["createDate"] as? String, raw.count >= 7 else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: String(raw.prefix(7)))
    }

    private static func fetchMonth(userId: String, month: String) async -> [String] {
        guard let data = await get(url(base: checkInHost, path: "getReportInfoListByIdAndMonth", query: [
            "userId": userId,
            "monthDate": month + "-"
        ])) else { return [] }
        let rows = arrayPayload(data)
        return rows.compactMap { row in
            normalize(row["date"] as? String)
        }
    }

    private static func studyDurations(userId: String) async -> [String: Int] {
        guard let data = await get(url(base: personalHost, path: "study/duration", query: ["user_id": userId])),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json["data"] as? [[String: Any]] else { return [:] }
        var durations: [String: Int] = [:]
        for row in rows {
            guard let date = row["date"] as? String, !date.isEmpty else { continue }
            let value = row["play_duration_ms"]
            let milliseconds: Int
            if let number = value as? Int {
                milliseconds = number
            } else if let number = value as? Double {
                milliseconds = Int(number)
            } else if let number = value as? NSNumber {
                milliseconds = number.intValue
            } else {
                milliseconds = 0
            }
            durations[String(date.prefix(10))] = milliseconds
        }
        return durations
    }

    private static func completedCount(userId: String) async -> Int {
        guard let data = await get(url(base: personalHost, path: "study/completed", query: ["user_id": userId])),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json["data"] as? [Any] else { return 0 }
        return rows.count
    }

    private static func arrayPayload(_ data: Data) -> [[String: Any]] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return [] }
        if let rows = json as? [[String: Any]] { return rows }
        if let object = json as? [String: Any], let rows = object["data"] as? [[String: Any]] { return rows }
        return []
    }

    private static func normalize(_ date: String?) -> String? {
        guard let date else { return nil }
        let parts = date.trimmingCharacters(in: .whitespaces).split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else { return nil }
        let dayText = parts[2].prefix { $0.isNumber }
        guard let day = Int(dayText) else { return nil }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func get(_ url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              !data.isEmpty else { return nil }
        return data
    }

    private static func url(base: String, path: String, query: [String: String]) -> URL {
        var components = URLComponents(string: base + path)!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }

    private static let checkInHost = "http://app.htzchina.org:8081/"
    private static let personalHost = "http://app.htzchina.org:8082/htz-api-pyservice/api/v1/"

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func monthKey(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private static func weekLabel(_ date: Date, calendar: Calendar) -> String {
        switch calendar.component(.weekday, from: date) {
        case 1: return "日"
        case 2: return "一"
        case 3: return "二"
        case 4: return "三"
        case 5: return "四"
        case 6: return "五"
        default: return "六"
        }
    }
}
