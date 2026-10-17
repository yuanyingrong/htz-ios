import Foundation

public enum PlayMode: Int, Equatable, CaseIterable, Sendable {
    case sequential = 0
    case shuffle = 1
    case loop = 2
    case single = 3

    public var systemImage: String {
        switch self {
        case .sequential: return "arrow.right"
        case .shuffle: return "shuffle"
        case .loop: return "repeat"
        case .single: return "repeat.1"
        }
    }

    public var title: String {
        switch self {
        case .sequential: return "顺序播放"
        case .shuffle: return "随机播放"
        case .loop: return "列表循环"
        case .single: return "单曲循环"
        }
    }

    public func cycled() -> PlayMode {
        PlayMode(rawValue: (rawValue + 1) % PlayMode.allCases.count) ?? .sequential
    }
}

enum PlayModeStore {
    private static let key = "htz.playMode"

    static var current: PlayMode {
        get { PlayMode(rawValue: UserDefaults.standard.integer(forKey: key)) ?? .sequential }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}
