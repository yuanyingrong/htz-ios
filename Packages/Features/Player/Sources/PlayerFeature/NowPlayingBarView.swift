import SwiftUI
import UIKit
import ComposableArchitecture
import DesignSystem
import HTZAudio
public struct NowPlayingBarView: View {
    let store: StoreOf<PlayerFeature>

    public init(store: StoreOf<PlayerFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            if let item = store.currentItem {
                VStack(spacing: 0) {
                    ProgressView(value: store.progress)
                        .progressViewStyle(.linear)
                        .tint(.htzAccent)
                        .padding(.bottom, -6)

                    HStack(spacing: HTZSpacing.sm) {
                        artwork(item.imageUrl)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.htzBody)
                                .foregroundColor(.htzLabel)
                                .lineLimit(1)
                            if let artist = item.artist, !artist.isEmpty {
                                Text(artist)
                                    .font(.htzCaption)
                                    .foregroundColor(.htzLabel.opacity(0.6))
                                    .lineLimit(1)
                            }
                        }
                        .onTapGesture { store.send(.openFullPlayer) }
                        Spacer()
                        Button {
                            if store.isPlaying {
                                store.send(.pauseButtonTapped)
                            } else {
                                store.send(.playButtonTapped)
                            }
                        } label: {
                            Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.htzLabel)
                        }
                        .frame(width: 44, height: 44)
                        Button {
                            store.send(.nextTrack)
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(.htzLabel)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, HTZSpacing.md)
                    .padding(.vertical, HTZSpacing.sm)
                }
                .frame(height: 64)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 10, y: -2)
                .contentShape(Rectangle())
                .accessibilityIdentifier("now-playing-bar")
                .accessibilityValue(store.error ?? (store.currentTime > 0.3 ? "playing" : "buffering"))
                .onTapGesture { store.send(.openFullPlayer) }
            }
        }
    }

    private func artwork(_ url: URL?) -> some View {
        AsyncImage(url: url) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: 6).fill(Color.htzBackground.opacity(0.3))
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture { store.send(.openFullPlayer) }
    }
}

public struct FullPlayerView: View {
    let store: StoreOf<PlayerFeature>
    private let rates = [0.75, 1.0, 1.25, 1.5, 2.0]
    @State private var showFont = false
    @State private var lyricSize: Double = 17
    @State private var showList = false
    @State private var showTimer = false
    @State private var sleepMinutes: Int?
    @State private var previewTime: Double?

    public init(store: StoreOf<PlayerFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        chip("原文", selected: store.lyricKind == .original) {
                            showFont = false
                            store.send(.setLyricKind(store.lyricKind == .original ? .explanation : .original))
                        }
                        chip("字号", selected: showFont) { showFont.toggle() }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if showFont {
                        HStack {
                            Text("字号")
                            Slider(value: $lyricSize, in: 14...28, step: 1)
                            Text("\(Int(lyricSize))")
                                .frame(width: 28)
                        }
                        .font(.system(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    LyricPage(
                        lines: store.lyricLines,
                        activeIndex: store.activeLyricIndex,
                        fontSize: lyricSize,
                        onSelect: { store.send(.seek($0)) }
                    )
                    .equatable()
                    .background(Color.white)

                    controlPanel
                }
                .background(Color(white: 0.96))
                .navigationTitle(store.currentItem?.title ?? "正在播放")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            store.send(.closeFullPlayer)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
                .sheet(isPresented: $showList) {
                    PlaylistSheet(store: store)
                        .presentationDetents([.medium, .large])
                }
                .confirmationDialog("定时关闭", isPresented: $showTimer, titleVisibility: .visible) {
                    ForEach([15, 30, 45, 60], id: \.self) { minutes in
                        Button("\(minutes) 分钟") { sleepMinutes = minutes }
                    }
                    if sleepMinutes != nil {
                        Button("取消定时", role: .destructive) { sleepMinutes = nil }
                    }
                    Button("关闭", role: .cancel) {}
                }
                .alert("提示", isPresented: Binding(
                    get: { store.alertMessage != nil },
                    set: { if !$0 { store.send(.clearAlert) } }
                )) {
                    Button("好的", role: .cancel) { store.send(.clearAlert) }
                } message: {
                    Text(store.alertMessage ?? "")
                }
            }
            .task(id: sleepMinutes) {
                guard let sleepMinutes else { return }
                do {
                    try await Task.sleep(nanoseconds: UInt64(sleepMinutes) * 60 * 1_000_000_000)
                    store.send(.pauseButtonTapped)
                } catch {}
            }
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 8) {
            HStack {
                panelButton("arrow.down") { store.send(.downloadCurrent) }
                Spacer()
                Button {
                    let next = rates.first(where: { $0 > store.rate + 0.01 }) ?? rates[0]
                    store.send(.setRate(next))
                } label: {
                    Text(String(format: store.rate.truncatingRemainder(dividingBy: 1) == 0 ? "%.1f" : "%g", store.rate))
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 36, height: 28)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                Spacer()
                panelButton(store.isFavorite ? "star.fill" : "star") {
                    store.send(.toggleFavorite)
                }
                Spacer()
                panelButton(store.playMode.systemImage) {
                    store.send(.cyclePlayMode)
                }
                Spacer()
                ShareLink(item: store.currentItem?.title ?? "") {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 40, height: 40)
                }
            }
            .foregroundColor(PlayerPalette.title)
            .padding(.horizontal, 8)

            HStack(spacing: 8) {
                Button {
                    store.send(.seek(max(0, store.currentTime - 15)))
                } label: {
                    skipLabel("15", system: "gobackward.15")
                }
                Text(Self.clock(previewTime ?? store.currentTime))
                    .font(.system(size: 12))
                    .frame(width: 44)
                PlaybackSlider(
                    time: store.currentTime,
                    duration: store.duration,
                    onPreview: { previewTime = $0 },
                    onSeek: { store.send(.seek($0)) }
                )
                Text(Self.clock(store.duration))
                    .font(.system(size: 12))
                    .frame(width: 44)
                Button {
                    store.send(.seek(min(store.duration, store.currentTime + 15)))
                } label: {
                    skipLabel("15", system: "goforward.15")
                }
            }
            .foregroundColor(PlayerPalette.label)
            .padding(.horizontal, 8)

            HStack {
                Button { showList = true } label: {
                    Image(systemName: "list.bullet")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { store.send(.previousTrack) } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
                Button {
                    store.send(store.isPlaying ? .pauseButtonTapped : .playButtonTapped)
                } label: {
                    Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
                Button { store.send(.nextTrack) } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
                Button { showTimer = true } label: {
                    Image(systemName: sleepMinutes == nil ? "timer" : "timer.circle.fill")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(PlayerPalette.title)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .padding(.top, 6)
        .background(Color(white: 0.94))
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(selected ? .white : PlayerPalette.title)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selected ? Color(white: 0.75) : Color(white: 0.93), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func panelButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system).frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }

    private func skipLabel(_ text: String, system: String) -> some View {
        Image(systemName: system).font(.system(size: 22))
    }

    private static func clock(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "00:00" }
        let total = Int(seconds)
        let hours = total / 3600
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, (total % 3600) / 60, total % 60)
        }
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct PlaybackSlider: UIViewRepresentable {
    var time: Double
    var duration: Double
    var onPreview: (Double?) -> Void
    var onSeek: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPreview: onPreview, onSeek: onSeek)
    }

    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumTrackTintColor = UIColor(red: 77 / 255, green: 77 / 255, blue: 77 / 255, alpha: 1)
        slider.maximumTrackTintColor = UIColor(white: 0.85, alpha: 1)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.ended(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return slider
    }

    func updateUIView(_ slider: UISlider, context: Context) {
        context.coordinator.onPreview = onPreview
        context.coordinator.onSeek = onSeek
        let upper = Float(max(duration, 1))
        if slider.maximumValue != upper {
            slider.maximumValue = upper
        }
        guard !slider.isTracking else { return }
        let next = Float(min(max(time, 0), Double(upper)))
        if abs(slider.value - next) > 0.05 {
            slider.setValue(next, animated: false)
        }
    }

    final class Coordinator: NSObject {
        var onPreview: (Double?) -> Void
        var onSeek: (Double) -> Void

        init(onPreview: @escaping (Double?) -> Void, onSeek: @escaping (Double) -> Void) {
            self.onPreview = onPreview
            self.onSeek = onSeek
        }

        @objc func changed(_ slider: UISlider) {
            onPreview(Double(slider.value))
        }

        @objc func ended(_ slider: UISlider) {
            onPreview(nil)
            onSeek(Double(slider.value))
        }
    }
}

private struct LyricPage: View, Equatable {
    let lines: [LyricLine]
    let activeIndex: Int?
    let fontSize: Double
    let onSelect: (Double) -> Void
    @State private var follow = true
    @State private var followToken = 0

    static func == (lhs: LyricPage, rhs: LyricPage) -> Bool {
        lhs.activeIndex == rhs.activeIndex
            && lhs.fontSize == rhs.fontSize
            && lhs.lines.count == rhs.lines.count
            && lhs.lines.first?.millisecond == rhs.lines.first?.millisecond
            && lhs.lines.last?.millisecond == rhs.lines.last?.millisecond
    }

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {
                        Color.clear.frame(height: geo.size.height * 0.42)
                        if lines.isEmpty {
                            Text("暂无歌词")
                                .foregroundColor(PlayerPalette.label)
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                                Text(line.text)
                                    .font(.system(size: fontSize, weight: index == activeIndex ? .semibold : .regular))
                                    .foregroundColor(index == activeIndex ? .black : Color(white: 0.62))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        follow = true
                                        onSelect(line.time)
                                    }
                                    .id(index)
                            }
                        }
                        Color.clear.frame(height: geo.size.height * 0.42)
                    }
                    .padding(.horizontal, 28)
                }
                .onAppear {
                    guard let activeIndex else { return }
                    proxy.scrollTo(activeIndex, anchor: .center)
                }
                .onChange(of: activeIndex) { index in
                    guard follow, let index else { return }
                    withAnimation(.easeInOut(duration: 0.55)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { _ in follow = false }
                        .onEnded { _ in
                            followToken += 1
                            let token = followToken
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                if token == followToken { follow = true }
                            }
                        }
                )
            }
        }
    }
}

private struct PlaylistSheet: View {
    let store: StoreOf<PlayerFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(Array(store.queue.enumerated()), id: \.element.id) { index, track in
                Button {
                    store.send(.selectTrack(index))
                    dismiss()
                } label: {
                    HStack {
                        Text(track.title)
                            .foregroundColor(index == store.index ? PlayerPalette.orange : PlayerPalette.title)
                            .lineLimit(1)
                        Spacer()
                        if index == store.index {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(PlayerPalette.orange)
                        }
                    }
                }
            }
            .navigationTitle("播放列表")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private enum PlayerPalette {
    static let title = Color(red: 77 / 255, green: 77 / 255, blue: 77 / 255)
    static let label = Color(red: 154 / 255, green: 154 / 255, blue: 154 / 255)
    static let orange = Color(red: 1, green: 0.48, blue: 0.18)
}
