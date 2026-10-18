import Foundation
import NetworkKit

/// Accumulates how long audio was actually playing, per day and per account.
///
/// Mirrors the Android `play_duration_ms` bookkeeping: wall-clock time while playing, so
/// background/lock-screen listening counts and playback rate does not inflate it.
/// Totals are cumulative per day, which keeps server uploads idempotent (the server merges with MAX).
public final class StudyTimeTracker: @unchecked Sendable {
    public static let shared = StudyTimeTracker()

    public enum Report: Equatable, Sendable {
        case none
        case due
    }

    private let lock = NSLock()
    private let defaults: UserDefaults
    private let now: @Sendable () -> TimeInterval
    private let userId: @Sendable () -> String?
    private let reportInterval: TimeInterval
    private var lastTick: TimeInterval?
    private var wasPlaying = false
    private var lastReport: TimeInterval = 0
    /// Longest gap between two ticks still counted as continuous playback.
    private let maxGap: TimeInterval = 2

    init(
        defaults: UserDefaults = .standard,
        now: @escaping @Sendable () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        userId: @escaping @Sendable () -> String? = { AuthManager.shared.unionid },
        reportInterval: TimeInterval = 60
    ) {
        self.defaults = defaults
        self.now = now
        self.userId = userId
        self.reportInterval = reportInterval
    }

    /// Call on every player-state update. Returns `.due` when the totals should be uploaded.
    public func tick(isPlaying: Bool) -> Report {
        lock.lock()
        defer { lock.unlock() }
        let current = now()
        var report = Report.none
        if isPlaying, wasPlaying, let last = lastTick {
            let delta = current - last
            if delta > 0, delta <= maxGap { add(seconds: delta) }
        }
        if wasPlaying, !isPlaying {
            report = .due
        } else if isPlaying, current - lastReport >= reportInterval {
            report = .due
        }
        if report == .due { lastReport = current }
        wasPlaying = isPlaying
        lastTick = current
        return report
    }

    /// Per-day totals (`yyyy-MM-dd` → ms) for this account.
    public func totals() -> [String: Int] {
        lock.lock()
        defer { lock.unlock() }
        return load()
    }

    /// The most recent `days` days that have data, used for uploads.
    public func recentTotals(days: Int = 2) -> [String: Int] {
        let all = totals()
        let keys = Self.recentKeys(days: days)
        return all.filter { keys.contains($0.key) && $0.value > 0 }
    }

    // MARK: Storage

    private var storageKey: String? {
        guard let id = userId(), !id.isEmpty else { return nil }
        return "study.playMs.\(id)"
    }

    private func load() -> [String: Int] {
        guard let key = storageKey else { return [:] }
        return (defaults.dictionary(forKey: key) as? [String: Int]) ?? [:]
    }

    private func add(seconds: TimeInterval) {
        guard let key = storageKey else { return }
        var all = (defaults.dictionary(forKey: key) as? [String: Int]) ?? [:]
        let day = Self.dayKey(Date())
        all[day, default: 0] += Int((seconds * 1000).rounded())
        defaults.set(all, forKey: key)
    }

    static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func recentKeys(days: Int) -> Set<String> {
        let calendar = Calendar.current
        return Set((0..<max(days, 1)).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date()).map(dayKey)
        })
    }
}
