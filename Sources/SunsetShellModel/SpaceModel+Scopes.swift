package import SunsetPane

/// A Space when a scope of the app is turned off (roadmap 0033; ADR-0056): its panes of that kind close.
extension SpaceModel {
    /// The panes of its tabs that are of the scope: running, or waiting to be made.
    private func panes(of scope: Scopes.Scope) -> [PaneID] {
        tabs.allPanes.filter { (contents[$0]?.descriptor.kind ?? pending[$0]?.kind) == scope.kind }
    }

    /// How many of its tabs have a pane of the scope.
    package func count(of scope: Scopes.Scope) -> Int {
        let its = Set(panes(of: scope))
        return tabs.items.count { !its.isDisjoint(with: $0.panes) }
    }

    /// Closes every pane of the scope: a tab of only those goes; a split keeps its other panes. Through a window that
    /// shows the Space when there is one (it moves to a neighbour as when a tab closes), else directly.
    package func close(_ scope: Scopes.Scope) {
        for pane in panes(of: scope) {
            if contents[pane] != nil {
                ended(pane)
            } else {
                tabs.close(pane: pane)
                pending[pane] = nil
            }
        }
        if tabs.isEmpty { stopped = nil }
    }
}
