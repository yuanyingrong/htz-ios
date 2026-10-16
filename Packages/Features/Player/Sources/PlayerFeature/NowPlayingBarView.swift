import SwiftUI
import ComposableArchitecture
import DesignSystem
import HTZAudio
import NetworkKit

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
    @State private var favorited = false

    public init(store: StoreOf<PlayerFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        chip("原文", selected: !showFont) {
                            showFont = false
                            store.send(.setLyricKind(.original))
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

                    ScrollViewReader { proxy in
                        ScrollView {
                            if store.lyricLines.isEmpty {
                                Text("暂无歌词")
                                    .foregroundColor(PlayerPalette.label)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 80)
                            } else {
                                VStack(spacing: 22) {
                                    ForEach(Array(store.lyricLines.enumerated()), id: \.offset) { index, line in
                                        Text(line.text)
                                            .font(.system(size: lyricSize, weight: index == store.activeLyricIndex ? .bold : .regular))
                                            .foregroundColor(index == store.activeLyricIndex ? .black : Color(white: 0.62))
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)
                                            .id(index)
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 24)
                            }
                        }
                        .onChange(of: store.activeLyricIndex) { index in
                            guard let index else { return }
                            withAnimation { proxy.scrollTo(index, anchor: .center) }
                        }
                    }
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
                panelButton(favorited ? "star.fill" : "star") {
                    favorited = true
                    let itemId = store.currentItem?.id ?? ""
                    Task { try? await LibraryAPI.addFavorite(itemId: itemId) }
                }
                Spacer()
                panelButton("repeat") {}
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
                Text(Self.clock(store.currentTime))
                    .font(.system(size: 12))
                    .frame(width: 44)
                Slider(
                    value: Binding(get: { store.currentTime }, set: { store.send(.seek($0)) }),
                    in: 0...max(store.duration, 1)
                )
                .tint(PlayerPalette.title)
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
                Spacer()
                Button { store.send(.previousTrack) } label: {
                    Image(systemName: "backward.end.fill").font(.title3)
                }
                Spacer()
                Button {
                    store.send(store.isPlaying ? .pauseButtonTapped : .playButtonTapped)
                } label: {
                    Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .frame(width: 56, height: 56)
                }
                Spacer()
                Button { store.send(.nextTrack) } label: {
                    Image(systemName: "forward.end.fill").font(.title3)
                }
                Spacer()
                Button { showTimer = true } label: {
                    Image(systemName: sleepMinutes == nil ? "timer" : "timer.circle.fill")
                        .frame(width: 44, height: 44)
                }
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
