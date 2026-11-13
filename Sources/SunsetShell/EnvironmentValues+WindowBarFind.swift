package import SwiftUI

extension EnvironmentValues {
    /// The window bar shows the focused page's find bar in its row (at its edge, beside the address): the focused pane does not
    /// draw its own (owner, 2026-11-13: one row, one layer).
    @Entry package var windowBarHostsFind = false
    /// Set by `View.barGroupBlurs()`: the groups inside publish where they are and the container draws every blur beneath all of
    /// them, so that no group's blur falls over another group's glass.
    @Entry package var barGroupBlursBelow = false
}
