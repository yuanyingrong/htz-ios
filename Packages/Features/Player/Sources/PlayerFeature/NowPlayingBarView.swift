import SwiftUI
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
                    // Progress Bar
                    ProgressView(value: store.progress)
                        .progressViewStyle(.linear)
                        .tint(.htzAccent)
                        .padding(.bottom, -6) // Overlap a bit
                    
                    HStack(spacing: HTZSpacing.sm) {
                        // Artwork
                        AsyncImage(url: item.imageUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.htzBackground.opacity(0.3))
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(radius: 4)
                        
                        // Title
                        Text(item.title)
                            .font(.htzBody)
                            .foregroundColor(.htzLabel)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Play/Pause Button
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
                        
                        // Forward Button (placeholder)
                        Button {
                            // Forward action
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
                .background(.ultraThinMaterial)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
