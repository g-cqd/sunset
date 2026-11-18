import SunsetHelp
import SwiftUI

/// A kept page away from where it was kept (the owner's note n3): a small turn-back arrow in its corner; a double click on the
/// row takes it back.
struct AwayBadge: View {
    var body: some View {
        Image(systemName: "arrow.uturn.backward.circle.fill")
            .font(.system(size: Design.Symbol.badge))
            .foregroundStyle(.secondary)
            .padding(Design.Space.xs)
            .helpTopic(.pinned)
            .accessibilityLabel("Away from where it was kept")
            .transition(.opacity)
    }
}
