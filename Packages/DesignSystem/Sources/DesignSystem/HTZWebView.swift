import SwiftUI
import WebKit

public enum HTZWebContent: Equatable {
    case url(URL)
    case html(String, baseURL: URL?)
}

/// In-app browser page used for agreements, purchase, check-in and help pages.
public struct HTZWebPage: View {
    private let title: String
    private let content: HTZWebContent
    private let localStorage: [String: String]
    private let resetsSiteData: Bool
    @State private var progress: Double = 0

    /// `localStorage` is written before any page script runs; `resetsSiteData` wipes the site's
    /// cookies and storage first (used when the logged-in account changed).
    public init(title: String, url: URL, localStorage: [String: String] = [:], resetsSiteData: Bool = false) {
        self.title = title
        self.content = .url(url)
        self.localStorage = localStorage
        self.resetsSiteData = resetsSiteData
    }

    public init(title: String, content: HTZWebContent) {
        self.title = title
        self.content = content
        self.localStorage = [:]
        self.resetsSiteData = false
    }

    public var body: some View {
        HTZWebView(content: content, localStorage: localStorage, resetsSiteData: resetsSiteData, progress: $progress)
            .overlay(alignment: .top) {
                if progress < 1 {
                    ProgressView(value: progress)
                        .tint(HTZColor.ctaStart)
                        .scaleEffect(x: 1, y: 0.6, anchor: .top)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .htzPage(title)
    }
}

public struct HTZWebView: UIViewRepresentable {
    private let content: HTZWebContent
    private let localStorage: [String: String]
    private let resetsSiteData: Bool
    @Binding private var progress: Double

    public init(
        content: HTZWebContent,
        localStorage: [String: String] = [:],
        resetsSiteData: Bool = false,
        progress: Binding<Double> = .constant(1)
    ) {
        self.content = content
        self.localStorage = localStorage
        self.resetsSiteData = resetsSiteData
        self._progress = progress
    }

    public func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        if let script = Self.storageScript(localStorage) {
            configuration.userContentController.addUserScript(
                WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )
        }
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        context.coordinator.observation = webView.observe(\.estimatedProgress, options: [.new]) { view, _ in
            let value = view.estimatedProgress
            DispatchQueue.main.async { context.coordinator.progress.wrappedValue = value }
        }
        if resetsSiteData, case let .url(url) = content, let host = url.host {
            let store = WKWebsiteDataStore.default()
            store.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                let matching = records.filter { host.hasSuffix($0.displayName) || $0.displayName.hasSuffix(host) }
                store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: matching) {
                    context.coordinator.load(content, in: webView)
                }
            }
        } else {
            context.coordinator.load(content, in: webView)
        }
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        if let loaded = context.coordinator.loaded, loaded != content {
            context.coordinator.load(content, in: uiView)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(progress: $progress)
    }

    /// Mirrors the Android app: every value is stored as `JSON.stringify(value)`.
    static func storageScript(_ values: [String: String]) -> String? {
        guard !values.isEmpty else { return nil }
        let statements = values.keys.sorted().compactMap { key -> String? in
            guard let keyLiteral = jsLiteral(key), let valueLiteral = jsLiteral(values[key] ?? "") else { return nil }
            return "localStorage.setItem(\(keyLiteral), JSON.stringify(\(valueLiteral)));"
        }
        return "try {\(statements.joined())} catch (e) {}"
    }

    private static func jsLiteral(_ value: String) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: [value]),
              let array = String(data: data, encoding: .utf8) else { return nil }
        return String(array.dropFirst().dropLast())
    }

    public final class Coordinator: NSObject, WKNavigationDelegate {
        let progress: Binding<Double>
        var observation: NSKeyValueObservation?
        var loaded: HTZWebContent?

        init(progress: Binding<Double>) {
            self.progress = progress
        }

        func load(_ content: HTZWebContent, in webView: WKWebView) {
            loaded = content
            switch content {
            case let .url(url):
                webView.load(URLRequest(url: url))
            case let .html(html, baseURL):
                webView.loadHTMLString(html, baseURL: baseURL)
            }
        }

        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
            let scheme = url.scheme?.lowercased() ?? ""
            if scheme == "weixin" || scheme == "wechat" || url.host?.contains("open.weixin.qq.com") == true {
                return decisionHandler(.cancel)
            }
            if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "data" {
                return decisionHandler(.allow)
            }
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}

public enum SimpleMarkdown {
    /// Enough Markdown for the help document: headings, bold, images, links, paragraphs; inline HTML passes through.
    public static func html(_ markdown: String) -> String {
        var blocks: [String] = []
        var paragraph: [String] = []

        func flush() {
            guard !paragraph.isEmpty else { return }
            let text = paragraph.joined(separator: "<br>")
            blocks.append(text.hasPrefix("<") ? text : "<p>\(text)</p>")
            paragraph = []
        }

        for raw in markdown.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flush()
            } else if let level = headingLevel(line) {
                flush()
                let text = String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                blocks.append("<h\(level)>\(inline(text))</h\(level)>")
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flush()
                blocks.append("<li>\(inline(String(line.dropFirst(2))))</li>")
            } else {
                paragraph.append(inline(line))
            }
        }
        flush()

        return """
        <html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        body{font:-apple-system-body;color:#333;padding:16px;line-height:1.6;word-wrap:break-word}
        h1,h2,h3{color:#4D4D4D;margin:20px 0 8px} img{max-width:100%;height:auto;border-radius:6px}
        li{margin-left:18px}
        </style></head><body>\(blocks.joined(separator: "\n"))</body></html>
        """
    }

    private static func headingLevel(_ line: String) -> Int? {
        let hashes = line.prefix { $0 == "#" }.count
        guard (1...6).contains(hashes), line.dropFirst(hashes).first == " " else { return nil }
        return hashes
    }

    private static func inline(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: #"!\[([^\]]*)\]\(([^)]+)\)"#, with: "<img alt=\"$1\" src=\"$2\">", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*\*([^*]+)\*\*"#, with: "<b>$1</b>", options: .regularExpression)
        return result
    }
}
