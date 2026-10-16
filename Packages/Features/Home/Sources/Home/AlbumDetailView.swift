import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature
import HTZAudio

public struct AlbumDetailView: View {
    let store: StoreOf<AlbumDetailFeature>
    @State private var showPicker = false

    public init(store: StoreOf<AlbumDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        header
                        actionBar
                        if let title = store.resumeTitle, !title.isEmpty {
                            resumeBar(title)
                        }
                        episodeList
                    }
                    .padding(.bottom, 120)
                }
                .background(AlbumPalette.page)
                .sheet(isPresented: $showPicker) {
                    EpisodePicker(items: store.items) { id in
                        showPicker = false
                        proxy.scrollTo(id, anchor: .top)
                    }
                    .presentationDetents([.medium])
                }
            }
            .navigationTitle(store.album.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            SearchView()
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        ShareLink(item: store.album.name) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .alert("提示", isPresented: Binding(
                get: { store.alertMessage != nil },
                set: { if !$0 { store.send(.clearAlert) } }
            )) {
                Button("好的", role: .cancel) { store.send(.clearAlert) }
            } message: {
                Text(store.alertMessage ?? "")
            }
            .onAppear { store.send(.onAppear) }
            .overlay {
                if store.isResolvingAudio {
                    ProgressView()
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: store.album.imageUrl.flatMap(URL.init)) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                default:
                    AlbumPalette.banner
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(store.album.description ?? "")
                .font(.system(size: 13))
                .foregroundColor(AlbumPalette.label)
                .lineSpacing(4)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }

    private var actionBar: some View {
        HStack(spacing: 0) {
            actionButton("arrow.up.arrow.down", "排序") { store.send(.toggleSort) }
            divider
            actionButton("list.bullet", "选集") { showPicker = true }
            divider
            actionButton("arrow.down", "下载") { store.send(.downloadAlbum) }
        }
        .frame(height: 48)
        .background(Color.white)
    }

    private var divider: some View {
        Rectangle().fill(Color(white: 0.9)).frame(width: 1, height: 20)
    }

    private func actionButton(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14))
            .foregroundColor(AlbumPalette.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func resumeBar(_ title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "play.circle")
                .foregroundColor(AlbumPalette.title)
            Text(resumeText(title))
                .font(.system(size: 14))
                .foregroundColor(AlbumPalette.title)
                .lineLimit(1)
            Spacer()
            Button {
                playResume()
            } label: {
                Text("续播")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(AlbumPalette.orange, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color.white)
    }

    private func resumeText(_ title: String) -> String {
        let clock = AlbumTime.clock(store.resumePosition)
        return clock == "00:00" ? "续播 \(title)" : "续播 \(title) · \(clock)"
    }

    private func playResume() {
        guard let id = store.resumeItemId, let item = store.items.first(where: { $0.id == id }) else { return }
        store.send(.trackTapped(item))
    }

    @ViewBuilder
    private var episodeList: some View {
        if store.isLoading && store.items.isEmpty {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
        } else if let error = store.errorMessage, store.items.isEmpty {
            Text(error).foregroundColor(.red).padding()
        } else {
            LazyVStack(spacing: 0) {
                ForEach(store.items) { item in
                    Button {
                        store.send(.trackTapped(item))
                    } label: {
                        EpisodeRow(item: item, cover: store.album.imageUrl, progress: item.id == store.resumeItemId ? store.resumePosition : nil)
                    }
                    .buttonStyle(.plain)
                    .id(item.id)
                    Divider().padding(.leading, 76)
                }
            }
            .background(Color.white)
        }
    }
}

private struct EpisodeRow: View {
    let item: SutraItem
    let cover: String?
    let progress: Int?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            AsyncImage(url: cover.flatMap(URL.init)) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                default:
                    AlbumPalette.banner
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title ?? "未命名")
                    .font(.system(size: 15))
                    .foregroundColor(AlbumPalette.title)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    Label("\(item.playedCount ?? 0)", systemImage: "play.fill")
                    Label(AlbumTime.clock(item.duration ?? 0), systemImage: "clock")
                    if let remain = AlbumTime.remaining(duration: item.duration ?? 0, progress: progress) {
                        Text(remain)
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(AlbumPalette.label)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

private struct EpisodePicker: View {
    let items: [SutraItem]
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(groups, id: \.start) { group in
                Button("\(group.start + 1)-\(group.end)") {
                    if items.indices.contains(group.start) {
                        onPick(items[group.start].id)
                    }
                    dismiss()
                }
            }
            .navigationTitle("选集")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var groups: [(start: Int, end: Int)] {
        stride(from: 0, to: items.count, by: 50).map { start in
            (start, min(start + 50, items.count))
        }
    }
}

enum AlbumTime {
    static func clock(_ value: Int) -> String {
        let seconds = value >= 100_000 ? value / 1000 : value
        guard seconds > 0 else { return "00:00" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remain = seconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remain)
        }
        return String(format: "%02d:%02d", minutes, remain)
    }

    static func remaining(duration: Int, progress: Int?) -> String? {
        guard let progress, progress > 0, duration > 0 else { return nil }
        let durationMs = duration >= 100_000 ? duration : duration * 1000
        let progressMs = progress >= 100_000 ? progress : progress * 1000
        let left = durationMs - progressMs
        guard left > 5000 else { return nil }
        let minutes = (left + 59_999) / 60_000
        return "剩余\(minutes)分钟"
    }
}
