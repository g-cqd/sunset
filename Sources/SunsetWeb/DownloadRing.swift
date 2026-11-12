import SwiftUI

/// A ring that fills as a download goes, with rounded ends (the owner's note n61 for loading), around an arrow.
struct DownloadRing: View {
    let fraction: Double?
    let running: Bool

    var body: some View {
        ZStack {
            if running {
                Circle().stroke(Color.primary.opacity(0.15), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: max(fraction ?? 0.08, 0.04))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.2), value: fraction)
            }
            Image(systemName: "arrow.down")
                .font(.system(size: running ? 8 : 13, weight: running ? .semibold : .regular))
        }
        .frame(width: 16, height: 16)
    }
}
