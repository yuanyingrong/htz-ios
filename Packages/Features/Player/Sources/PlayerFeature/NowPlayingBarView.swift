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
                HStack(spacing: 10) {
                    artwork(item.imageUrl)
                    Button {
                        store.send(.openFullPlayer)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.system(size: 14))
                                .foregroundColor(PlayerPalette.title)
                                .lineLimit(1)
                            if let artist = item.artist, !artist.isEmpty {
                                Text(artist)
                                    .font(.system(size: 11))
                                    .foregroundColor(PlayerPalette.label)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        store.send(store.isPlaying ? .pauseButtonTapped : .playButtonTapped)
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color(white: 0.88), lineWidth: 2)
                            Circle()
                                .trim(from: 0, to: store.progress)
                                .stroke(PlayerPalette.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 13))
                                .foregroundColor(PlayerPalette.title)
                        }
                        .frame(width: 32, height: 32)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        store.send(.closeBarTapped)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(PlayerPalette.label)
                            .frame(width: 40, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("now-playing-close")
                }
                .padding(.leading, 8)
                .padding(.trailing, 6)
                .frame(height: 55)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 226 / 255, green: 226 / 255, blue: 226 / 255), lineWidth: 1))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                .accessibilityIdentifier("now-playing-bar")
                .accessibilityValue(store.error ?? (store.currentTime > 0.3 ? "playing" : "buffering"))
            }
        }
    }

    private func artwork(_ url: URL?) -> some View {
        AsyncImage(url: url) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: 6).fill(Color.htzBackground.opacity(0.3))
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture { store.send(.openFullPlayer) }
    }
}

public struct FullPlayerView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<PlayerFeature>
    @State private var showFont = false
    @State private var showList = false
    @State private var showTimer = false
    @State private var showSpeed = false
    @State private var showShare = false

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
                            Slider(
                                value: Binding(get: { store.lyricFontSize }, set: { store.send(.setLyricFontSize($0)) }),
                                in: 14...28,
                                step: 1
                            )
                            Text("\(Int(store.lyricFontSize))")
                                .frame(width: 28)
                        }
                        .font(.system(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    PlayerLyricSection(store: store)

                    controlPanel
                }
                .background(Color(white: 0.96))
                .navigationTitle(store.currentItem?.title ?? "正在播放")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.white, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
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
                        .presentationDetents([.fraction(0.75), .large])
                        .presentationDragIndicator(.visible)
                        .modifier(PlaylistCorners())
                }
                .sheet(isPresented: $showSpeed) {
                    WithPerceptionTracking {
                        SpeedSheet(rate: store.rate) { store.send(.setRate($0)) }
                            .modifier(PlaylistCorners())
                    }
                }
                .sheet(isPresented: $showShare) {
                    WithPerceptionTracking {
                        ShareSheet(
                            content: store.currentItem.map {
                                ShareContent.episode(id: $0.id, title: $0.title, album: $0.artist, imageURL: $0.imageUrl)
                            },
                            onWeChat: { store.send(.shareToWeChat($0)) }
                        )
                        .modifier(PlaylistCorners())
                    }
                }
                .sheet(isPresented: $showTimer) {
                    WithPerceptionTracking {
                        SleepTimerSheet(timer: store.sleepTimer) { store.send(.setSleepTimer($0)) }
                            .modifier(PlaylistCorners())
                    }
                }
                .htzToast($store.toast.sending(\.toastChanged))
                .onAppear { store.send(.fullPlayerAppeared) }
                .onDisappear { store.send(.fullPlayerDisappeared) }
            }
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Button { store.send(.downloadCurrent) } label: {
                    (store.isCurrentDownloaded ? HTZImage.downloaded : HTZImage.download)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
                Button { showSpeed = true } label: {
                    Text(Self.rateText(store.rate))
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 48, height: 28)
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
                panelButton("square.and.arrow.up") { showShare = true }
            }
            .foregroundColor(PlayerPalette.title)
            .padding(.horizontal, 8)

            PlayerProgressRow(store: store)

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
                    Image(systemName: store.sleepTimer == nil ? "timer" : "timer.circle.fill")
                        .foregroundColor(store.sleepTimer == nil ? PlayerPalette.title : PlayerPalette.orange)
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

    static func rateText(_ rate: Double) -> String {
        rate.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.1fx", rate) : String(format: "%gx", rate)
    }

    fileprivate static func clock(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "00:00" }
        let total = Int(seconds)
        let hours = total / 3600
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, (total % 3600) / 60, total % 60)
        }
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

/// Lyrics follow the playback position (`activeLyricIndex` reads `currentTime`), so they are isolated
/// from the page body for the same reason as `PlayerProgressRow`.
private struct PlayerLyricSection: View {
    let store: StoreOf<PlayerFeature>

    var body: some View {
        WithPerceptionTracking {
            LyricPage(
                lines: store.lyricLines,
                activeIndex: store.activeLyricIndex,
                fontSize: store.lyricFontSize,
                onSelect: { store.send(.seek($0)) }
            )
            .equatable()
            .background(Color.white)
        }
    }
}

/// The time-varying part of the player (position label, slider, ±15s). It lives in its own view so the
/// 4 Hz position updates only re-render this row — not the whole page. Re-evaluating the parent body
/// that often rebuilt the navigation bar items and swallowed taps on the back button.
private struct PlayerProgressRow: View {
    let store: StoreOf<PlayerFeature>
    @State private var previewTime: Double?

    var body: some View {
        WithPerceptionTracking {
            HStack(spacing: 8) {
                Button {
                    store.send(.seek(max(0, store.currentTime - 15)))
                } label: {
                    Image(systemName: "gobackward.15").font(.system(size: 22))
                }
                Text(FullPlayerView.clock(previewTime ?? store.currentTime))
                    .font(.system(size: 12))
                    .frame(width: 44)
                PlaybackSlider(
                    time: store.currentTime,
                    duration: store.duration,
                    onPreview: { previewTime = $0 },
                    onSeek: { store.send(.seek($0)) }
                )
                Text(FullPlayerView.clock(store.duration))
                    .font(.system(size: 12))
                    .frame(width: 44)
                Button {
                    store.send(.seek(min(store.duration, store.currentTime + 15)))
                } label: {
                    Image(systemName: "goforward.15").font(.system(size: 22))
                }
            }
            .foregroundColor(PlayerPalette.label)
            .padding(.horizontal, 8)
            .onChange(of: store.currentItem?.id) { _ in previewTime = nil }
        }
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
        if context.coordinator.isScrubbing {
            DispatchQueue.main.async { context.coordinator.finish(slider) }
            return
        }
        let next = Float(min(max(time, 0), Double(upper)))
        if abs(slider.value - next) > 0.05 {
            slider.setValue(next, animated: false)
        }
    }

    final class Coordinator: NSObject {
        var onPreview: (Double?) -> Void
        var onSeek: (Double) -> Void
        private(set) var isScrubbing = false

        init(onPreview: @escaping (Double?) -> Void, onSeek: @escaping (Double) -> Void) {
            self.onPreview = onPreview
            self.onSeek = onSeek
        }

        @objc func changed(_ slider: UISlider) {
            guard slider.isTracking else {
                finish(slider)
                return
            }
            isScrubbing = true
            onPreview(Double(slider.value))
        }

        @objc func ended(_ slider: UISlider) {
            finish(slider)
        }

        func finish(_ slider: UISlider) {
            guard isScrubbing else { return }
            isScrubbing = false
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
            WithPerceptionTracking {
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
}

/// 播放列表，对照安卓 `layout_pop_playlist` / `PopPlayListAdapter`：标题 + 数量、排序与播放模式、
/// 带封面/时长/下载/收藏的列表、底部「取消」。点某一行不关闭列表：当前这集在播就暂停，否则播放它。
private struct PlaylistSheet: View {
    let store: StoreOf<PlayerFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                header
                Rectangle().fill(PlaylistStyle.line).frame(height: 1)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(store.queue.enumerated()), id: \.element.id) { index, track in
                                PlaylistRow(
                                    track: track,
                                    isCurrent: index == store.index,
                                    isPlaying: index == store.index && store.isPlaying,
                                    isDownloaded: store.downloadedIDs.contains(track.id),
                                    isFavorite: store.queueFavorites[track.id] != nil,
                                    onTap: { tap(index) },
                                    onDownload: { store.send(.downloadTrack(index)) },
                                    onFavorite: { store.send(.toggleQueueFavorite(index)) }
                                )
                                .id(track.id)
                            }
                        }
                    }
                    .onAppear {
                        if let id = store.queue[safe: store.index]?.id { proxy.scrollTo(id, anchor: .top) }
                    }
                }
                Rectangle().fill(PlaylistStyle.line).frame(height: 1)
                Button { dismiss() } label: {
                    Text("取消")
                        .font(.system(size: 15))
                        .foregroundColor(PlayerPalette.title)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Color.white)
            .htzToast(Binding(get: { store.toast }, set: { store.send(.toastChanged($0)) }))
            .onAppear { store.send(.playlistAppeared) }
            .onDisappear { store.send(.playlistDisappeared) }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("播放列表")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(PlayerPalette.title)
            Text("\(store.queue.count)")
                .font(.system(size: 14))
                .foregroundColor(PlaylistStyle.hint)
            Spacer()
            Button { store.send(.reverseQueue) } label: {
                HTZImage.sort(ascending: !store.isQueueDescending)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
            Button { store.send(.cyclePlayMode) } label: {
                Image(systemName: store.playMode.systemImage)
                    .font(.system(size: 18))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(PlayerPalette.title)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private func tap(_ index: Int) {
        if index == store.index {
            store.send(store.isPlaying ? .pauseButtonTapped : .playButtonTapped)
        } else {
            store.send(.selectTrack(index))
        }
    }
}

private enum PlaylistStyle {
    static let line = Color(red: 238 / 255, green: 238 / 255, blue: 238 / 255)
    static let hint = Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255)
    static let normalTitle = Color(red: 107 / 255, green: 107 / 255, blue: 107 / 255)
}

struct PlaylistCorners: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCornerRadius(24).presentationBackground(Color.white)
        } else {
            content
        }
    }
}

private struct PlaylistRow: View {
    let track: QueueTrack
    let isCurrent: Bool
    let isPlaying: Bool
    let isDownloaded: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onDownload: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    cover
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title)
                            .font(.system(size: 14, weight: isCurrent ? .bold : .regular))
                            .foregroundColor(isCurrent ? PlayerPalette.title : PlaylistStyle.normalTitle)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if let duration = track.duration {
                            Text(FullPlayerView.clock(Double(duration)))
                                .font(.system(size: 11))
                                .foregroundColor(PlaylistStyle.hint)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onDownload) {
                (isDownloaded ? HTZImage.downloaded : HTZImage.download)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 34, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 17))
                    .foregroundColor(isFavorite ? PlayerPalette.title : PlaylistStyle.normalTitle)
                    .frame(width: 34, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PlaylistStyle.line).frame(height: 1).padding(.leading, 68)
        }
    }

    private var cover: some View {
        ZStack {
            AsyncImage(url: track.imageUrl) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(red: 236 / 255, green: 225 / 255, blue: 211 / 255)
            }
            .frame(width: 40, height: 40)
            .clipped()
            Color.black.opacity(0.2)
            if isCurrent {
                Image(systemName: "waveform")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}

private enum PlayerPalette {
    static let title = Color(red: 77 / 255, green: 77 / 255, blue: 77 / 255)
    static let label = Color(red: 154 / 255, green: 154 / 255, blue: 154 / 255)
    static let orange = Color(red: 1, green: 0.48, blue: 0.18)
}


// MARK: - 定时关闭（对齐安卓 dialog_sleep_timer / dialog_custom_sleep_timer）

private struct SleepSheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct SleepTimerSheet: View {
    let timer: SleepTimer?
    let onSelect: (SleepTimer?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showCustom = false
    @State private var hours = 0
    @State private var minutes = 45
    @State private var height: CGFloat = 360

    private static let ink = Color(red: 77 / 255, green: 77 / 255, blue: 77 / 255)
    private static let hint = Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255)
    private static let grey = Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255)

    var body: some View {
        Group {
            if showCustom { customPage } else { mainPage }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(GeometryReader { Color.clear.preference(key: SleepSheetHeightKey.self, value: $0.size.height) })
        .onPreferenceChange(SleepSheetHeightKey.self) { height = $0 }
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.visible)
    }

    // MARK: 主面板

    private var mainPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("定时")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Self.ink)
                .frame(maxWidth: .infinity)
            Text("设置定时关闭")
                .font(.system(size: 15))
                .foregroundColor(Self.ink)
                .padding(.top, 18)
            sectionTitle("按时间")
            HStack(spacing: 8) {
                ForEach([15, 30, 60, 90], id: \.self) { value in
                    optionButton("\(value)分", selected: isMinutes(value)) { apply(.minutes(value)) }
                }
                optionButton("自定义", selected: isCustomMinutes) { openCustom() }
            }
            .padding(.top, 10)
            sectionTitle("按集数")
            HStack(spacing: 8) {
                optionButton("播完本集", selected: timer == .episodes(1)) { apply(.episodes(1)) }
                ForEach([2, 3, 5], id: \.self) { count in
                    optionButton("播完\(count)集", selected: timer == .episodes(count)) { apply(.episodes(count)) }
                }
            }
            .padding(.top, 10)
            if timer != nil {
                Button { apply(nil) } label: {
                    Text("取消定时")
                        .font(.system(size: 15))
                        .foregroundColor(Self.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Self.grey, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 22)
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(Self.hint)
            .padding(.top, 18)
    }

    private func optionButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(selected ? .white : Self.ink)
                .padding(.horizontal, 2)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(selected ? Self.ink : Color(white: 0.957), in: Capsule())
                .overlay(Capsule().stroke(selected ? Self.ink : Color(white: 0.878), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func isMinutes(_ value: Int) -> Bool {
        if case .minutes(value) = timer { return true }
        return false
    }

    private var isCustomMinutes: Bool {
        if case let .minutes(value) = timer { return ![15, 30, 60, 90].contains(value) }
        return false
    }

    private func apply(_ value: SleepTimer?) {
        onSelect(value)
        dismiss()
    }

    // MARK: 自定义时间

    private func openCustom() {
        var total = 45
        if case let .minutes(value) = timer { total = value }
        total = max(1, min(12 * 60, total))
        hours = total / 60
        minutes = total % 60
        showCustom = true
    }

    private var customPage: some View {
        VStack(spacing: 0) {
            Text("自定义时间")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Self.ink)
            Text("选择定时关闭时间")
                .font(.system(size: 13))
                .foregroundColor(Self.hint)
                .padding(.top, 8)
            HStack(spacing: 0) {
                wheel("小时", selection: $hours, range: 0...12, padded: false)
                Rectangle().fill(Color(white: 0.933)).frame(width: 1, height: 120)
                wheel("分钟", selection: $minutes, range: 0...59, padded: true)
            }
            .padding(.top, 18)
            HStack(spacing: 12) {
                Button {
                    apply(.minutes(max(1, hours * 60 + minutes)))
                } label: {
                    Text("确定")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1, green: 107 / 255, blue: 53 / 255), Color(red: 247 / 255, green: 147 / 255, blue: 30 / 255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                }
                Button { dismiss() } label: {
                    Text("取消")
                        .font(.system(size: 15))
                        .foregroundColor(Self.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Self.grey, in: Capsule())
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
    }

    private func wheel(_ title: String, selection: Binding<Int>, range: ClosedRange<Int>, padded: Bool) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Self.ink)
            Picker(title, selection: selection) {
                ForEach(Array(range), id: \.self) { value in
                    Text(padded ? String(format: "%02d", value) : "\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .clipped()
        }
        .frame(maxWidth: .infinity)
    }
}
