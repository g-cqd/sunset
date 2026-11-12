import SunsetShell
import SwiftUI

/// The downloads symbol: an arrow in a circle; while something downloads, the circle is drawn as far round as the downloads have gone, by the
/// symbol itself (Variable Draw, macOS 26: owner, 2026-11-12), and the system animates it between values.
struct DownloadRing: View {
    let fraction: Double?
    let running: Bool

    var body: some View {
        Image(systemName: "arrow.down.circle", variableValue: running ? max(fraction ?? 0, Self.least) : nil)
            .symbolVariableValueMode(.draw)
            .font(.system(size: Design.Symbol.row))
    }

    /// While running with no fraction known yet, a sliver shows that something is under way.
    private static let least = 0.04
}
