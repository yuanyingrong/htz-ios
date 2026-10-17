import Foundation

public struct QueueTrack: Equatable, Sendable, Identifiable {
    public var id: String
    public var sutraId: String
    public var title: String
    public var artist: String?
    public var imageUrl: URL?
    public var audioURL: URL?
    public var originalLyricURL: URL?
    public var explanationLyricURL: URL?

    public init(
        id: String,
        sutraId: String,
        title: String,
        artist: String? = nil,
        imageUrl: URL? = nil,
        audioURL: URL? = nil,
        originalLyricURL: URL? = nil,
        explanationLyricURL: URL? = nil
    ) {
        self.id = id
        self.sutraId = sutraId
        self.title = title
        self.artist = artist
        self.imageUrl = imageUrl
        self.audioURL = audioURL
        self.originalLyricURL = originalLyricURL
        self.explanationLyricURL = explanationLyricURL
    }
}

public struct ResolvedAudio: Equatable, Sendable {
    public var audioURL: URL
    public var originalLyricURL: URL?
    public var explanationLyricURL: URL?

    public init(audioURL: URL, originalLyricURL: URL? = nil, explanationLyricURL: URL? = nil) {
        self.audioURL = audioURL
        self.originalLyricURL = originalLyricURL
        self.explanationLyricURL = explanationLyricURL
    }
}

public enum LyricKind: String, Equatable, Sendable {
    case original
    case explanation
}

public struct LyricLine: Equatable, Identifiable, Sendable {
    public var id: Int { millisecond }
    public var millisecond: Int
    public var text: String

    public init(millisecond: Int, text: String) {
        self.millisecond = millisecond
        self.text = text
    }

    public var time: Double { Double(millisecond) / 1000 }
}

public enum LyricParser {
    public static func parse(_ raw: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        for rawLine in raw.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("[") else { continue }
            var rest = line
            var stamps: [Int] = []
            while rest.hasPrefix("["), let close = rest.firstIndex(of: "]") {
                let stamp = rest[rest.index(after: rest.startIndex)..<close]
                if let ms = milliseconds(String(stamp)) {
                    stamps.append(ms)
                }
                rest = String(rest[rest.index(after: close)...])
            }
            let text = rest.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }
            for ms in stamps {
                lines.append(LyricLine(millisecond: ms, text: text))
            }
        }
        return lines.sorted { $0.millisecond < $1.millisecond }
    }

    /// Timed LRC when the file has stamps; otherwise show the plain lines in order.
    public static func lines(from raw: String) -> [LyricLine] {
        let parsed = parse(raw)
        if !parsed.isEmpty { return parsed }
        let lowered = raw.lowercased()
        if lowered.contains("<html") || lowered.contains("<error>") { return [] }
        let plain = raw.split(whereSeparator: \.isNewline).map {
            $0.trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty && !$0.hasPrefix("[") }
        return plain.enumerated().map { LyricLine(millisecond: $0.offset * 1000, text: String($0.element)) }
    }

    private static func milliseconds(_ stamp: String) -> Int? {
        let parts = stamp.split(separator: ":")
        guard parts.count == 2, let minutes = Int(parts[0]) else { return nil }
        let seconds = Double(parts[1].replacingOccurrences(of: ",", with: "."))
        guard let seconds else { return nil }
        return minutes * 60_000 + Int(seconds * 1000)
    }
}
