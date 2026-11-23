import SunsetShell
import SwiftUI

/// The downloads symbol: an arrow in a circle; while something downloads, the circle is drawn as far round as the downloads have gone, by the
/// symbol itself (Variable Draw, macOS 26), and the system animates it between values. Once they are done, a check in the
/// circle for `doneFor`, replacing the arrow by the symbol's own transition, then the arrow again (n137).
struct DownloadRing: View {
    let fraction: Double?
    let running: Bool
    var done = false

    /// How long the check stays.
    static let doneFor = Duration.seconds(3)

    var body: some View {
        Image(
            systemName: done ? "checkmark.circle" : "arrow.down.circle",
            variableValue: running ? max(fraction ?? 0, Self.least) : nil
        )
        .symbolVariableValueMode(.draw)
        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer)))
        .font(.system(size: Design.Symbol.row))
        .animation(.default, value: done)
    }

    /// While running with no fraction known yet, a sliver shows that something is under way.
    private static let least = 0.04
}
