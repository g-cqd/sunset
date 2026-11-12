import SunsetShell
import SwiftUI

/// The mark of a page over plain http in its address field: the symbol, with "Not Secure" shown beside it while the pointer is on it (owner note n64).
struct NotSecureMark: View {
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.slash")
            if hovered { Text("Not Secure").transition(.opacity.combined(with: .move(edge: .leading))) }
        }
        .font(Design.Text.detail)
        .foregroundStyle(.secondary)
        .fixedSize()
        .contentShape(.rect)
        .onHover { inside in withAnimation(.easeOut(duration: 0.15)) { hovered = inside } }
        .help("This page is over plain http: what it sends and receives can be read and changed on the way.")
        .accessibilityLabel("Not Secure")
    }
}
