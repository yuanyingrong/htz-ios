import ComposableArchitecture
import Foundation

public extension SharedKey where Self == AppStorageKey<Bool>.Default {
    /// 每日打卡 entry on Home and My; off by default like Android's `ten_year_checkin_enabled`.
    static var checkInEnabled: Self {
        Self[.appStorage("ten_year_checkin_enabled"), default: false]
    }
}

public extension SharedKey where Self == AppStorageKey<Double>.Default {
    static var lyricFontSize: Self {
        Self[.appStorage("lyric_font_size"), default: 17]
    }
}

public extension SharedKey where Self == InMemoryKey<Bool>.Default {
    /// A pushed page that owns the bottom edge (e.g. a batch-edit bar) sets this so the app shell
    /// hides the tab bar and the mini player instead of covering that page's controls.
    static var hidesBottomChrome: Self {
        Self[.inMemory("hides_bottom_chrome"), default: false]
    }
}

public enum AppSettings {
    public static let lyricFontSizes: [Double] = [14, 15, 17, 19, 22, 25]

    /// Clears every user preference back to the shipped defaults (恢复默认设置).
    public static func restoreDefaults() {
        @Shared(.checkInEnabled) var checkIn
        @Shared(.lyricFontSize) var fontSize
        $checkIn.withLock { $0 = false }
        $fontSize.withLock { $0 = 17 }
        PlayModeStore.current = .sequential
    }
}
