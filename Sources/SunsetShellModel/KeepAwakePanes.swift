import Observation
package import SunsetPane

/// What is kept awake, by pane: a tab's panes go with it wherever it goes (Today, the Favorites, the grid, another window
/// or Space), and so does what it was asked; panes are unique to the app (`PaneID` is a UUID), so one table serves every
/// window.
@MainActor @Observable
package final class KeepAwakePanes {
    package static let shared = KeepAwakePanes()

    package var until: [PaneID: KeepAwake] = [:]

    package init() {}

    /// What the panes were asked: the first of them that was asked anything.
    package func until(_ panes: [PaneID]) -> KeepAwake? {
        panes.lazy.compactMap { self.until[$0] }.first
    }

    /// Whether the pane is kept awake: a page there is never unloaded (S-f).
    package func keepsAwake(_ pane: PaneID) -> Bool {
        until[pane] != nil
    }

    /// Asks it of every one of the panes (a split's: all of them, so that any one of them carries it if it leaves).
    package func set(_ value: KeepAwake?, for panes: [PaneID]) {
        for pane in panes { until[pane] = value }
    }
}
