import SwiftUI
import NetworkKit
import DesignSystem

public struct SutraItemRowView: View {
    let index: Int
    let item: SutraItem
    
    public init(index: Int, item: SutraItem) {
        self.index = index
        self.item = item
    }
    
    public var body: some View {
        HStack(spacing: HTZSpacing.md) {
            // Sequential Number (Classical Style)
            Text("\(index)")
                .font(.htzBody.monospacedDigit())
                .foregroundColor(.htzLabel.opacity(0.4))
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: HTZSpacing.xs) {
                    Text(item.title ?? "Unknown Title")
                        .font(.htzHeadline)
                        .foregroundColor(.htzLabel)
                        .lineLimit(1)
                    
                    if item.isTrial == 1 {
                        Text("试听")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange))
                    }
                }
                
                if let lesson = item.lesson {
                    Text("Lesson \(lesson)")
                        .font(.htzCaption)
                        .foregroundColor(.htzLabel.opacity(0.6))
                }
            }
            
            Spacer()
            
            if item.isTrial == 0 {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.htzLabel.opacity(0.3))
            }
            
            // Duration or Play Icon
            if let durationMs = item.duration {
                let seconds = durationMs / 1000
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                Text(String(format: "%d:%02d", minutes, remainingSeconds))
                    .font(.htzCaption.monospacedDigit())
                    .foregroundColor(.htzLabel.opacity(0.4))
            }
            
            Button(action: {
                // Play action
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.htzLabel.opacity(0.6))
            }
        }
        .padding(.vertical, HTZSpacing.sm)
        .padding(.horizontal, HTZSpacing.md)
        .background(Color.htzBackground.opacity(0.001)) // Make entire row tappable
    }
}
