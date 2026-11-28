import SunsetShell
import SunsetShellModel
import SwiftUI

/// The first of two keys pressed, at the window's foot, until the second comes (`KeySequenceMonitor`).
struct PendingKeysHint: View {
    private let pending = PendingKeys.shared
    @Environment(\.controlActiveState) private var active

    var body: some View {
        if let first = pending.first, active == .key {
            Text("\(first.symbols) was pressed. Waiting for the second key\u{2026}")
                .font(Design.Text.detail)
                .padding(.horizontal, Design.Space.m)
                .padding(.vertical, Design.Space.s)
                .glassEffect(.regular, in: .capsule)
                .padding(.bottom, Design.Space.l)
                .transition(.opacity)
                .allowsHitTesting(false)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
