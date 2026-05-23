import SwiftUI
import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature
import HTZAudio

public struct AlbumDetailView: View {
    let store: StoreOf<AlbumDetailFeature>
    @Environment(\.playerStore) var playerStore
    @State private var scrollOffset: CGFloat = 0

    public init(store: StoreOf<AlbumDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .top) {
                // 1. Immersive Background (Synced with Home)
                ImmersiveBackgroundView(imageUrl: store.album.imageUrl.flatMap(URL.init))
                    .contentTransition(.opacity)

                // 2. Main Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Header
                        AlbumDetailHeaderView(album: store.album, scrollOffset: scrollOffset)

                        // Items List
                        VStack(alignment: .leading, spacing: 0) {
                            if store.isLoading && store.items.isEmpty {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, HTZSpacing.xxl)
                            } else if let error = store.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                                    SutraItemRowView(index: index + 1, item: item)
                                        .onTapGesture {
                                            guard let audioURLString = item.audio,
                                                  let audioURL = URL(string: audioURLString) else { return }
                                            playerStore.send(.play(PlayerItem(
                                                id: item.id,
                                                url: audioURL,
                                                title: item.title ?? "Unknown Title",
                                                artist: store.album.name,
                                                imageUrl: store.album.imageUrl.flatMap(URL.init)
                                            )))
                                        }
                                    Divider()
                                        .padding(.leading, HTZSpacing.md + 30 + HTZSpacing.md)
                                }
                            }
                        }
                        .background(Color.htzBackground.opacity(0.8))
                        .padding(.bottom, 100)
                    }
                    .scrollOffsetTracker($scrollOffset)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(store.album.name)
                        .font(.htzHeadline)
                        .opacity(scrollOffset < -120 ? 1 : 0)
                        .animation(.easeInOut, value: scrollOffset)
                }
            }
        }
    }
}

// MARK: - Scroll Offset Tracker

extension View {
    /// Tracks the nearest ScrollView's contentOffset.y and writes the negated
    /// value to the binding.  iOS 18+ uses onScrollGeometryChange; older
    /// versions bridge through UIScrollView KVO.
    func scrollOffsetTracker(_ offset: Binding<CGFloat>) -> some View {
        modifier(ScrollOffsetModifier(offset: offset))
    }
}

private struct ScrollOffsetModifier: ViewModifier {
    @Binding var offset: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    offset = -newValue
                }
        } else {
            content
                .overlay(
                    ScrollOffsetObserver { contentOffsetY in
                        offset = -contentOffsetY
                    }
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
                )
        }
    }
}

// MARK: - iOS 16/17: UIScrollView KVO Bridge

private struct ScrollOffsetObserver: UIViewRepresentable {
    let action: (CGFloat) -> Void

    func makeUIView(context: Context) -> ScrollObserverView {
        ScrollObserverView(action: action)
    }

    func updateUIView(_ uiView: ScrollObserverView, context: Context) {
        uiView.action = action
    }
}

private final class ScrollObserverView: UIView {
    var action: (CGFloat) -> Void
    private var observation: NSKeyValueObservation?

    init(action: @escaping (CGFloat) -> Void) {
        self.action = action
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        observation?.invalidate()
        observation = nil

        guard superview != nil else { return }

        // Walk up to find the host UIScrollView — SwiftUI uses one internally
        if let scrollView = findScrollView() {
            observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, change in
                guard let self, let offsetY = change.newValue?.y else { return }
                self.action(offsetY)
            }
        }
    }

    private func findScrollView() -> UIScrollView? {
        var view: UIView? = superview
        while let v = view {
            if let scrollView = v as? UIScrollView {
                return scrollView
            }
            view = v.superview
        }
        return nil
    }
}
