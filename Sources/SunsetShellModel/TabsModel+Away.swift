import Foundation
package import SunsetPane

/// A kept page away from where it was kept: its row says so, and a double click takes it back.
extension TabsModel {
    /// Whether an open kept entry's shown pane is somewhere else than where it was kept: a page at another address (its
    /// fragment aside), a document another one. A terminal is never away: its folder changes as it works.
    package func isAway(entry: Favorites.Entry) -> Bool {
        guard let open = entry.open, let now = content(open.focused)?.descriptor,
            let then = entry.home.contents[open.focused] ?? entry.home.contents[entry.home.focused]
        else { return false }
        if let address = now.state["url"], let kept = then.state["url"] {
            return Self.withoutFragment(address) != Self.withoutFragment(kept)
        }
        if let document = now.state["document"], let kept = then.state["document"] { return document != kept }
        return false
    }

    /// A double click on a kept entry's row: back where it was kept when it is away; else its name is edited, as on a tab.
    package func doubleClick(entry id: Favorites.NodeID) {
        if let entry = keeper(of: id).favorites.entry(id), isAway(entry: entry) {
            renamingRow = nil
            return reset(entry: id)
        }
        renamingRow = .node(id)
    }

    /// Whether a kept entry has a terminal among its panes, live or saved: only then has it a command to edit or run.
    package func runsTerminal(_ entry: Favorites.Entry) -> Bool {
        let panes = entry.open?.panes ?? entry.home.layout.panes
        return panes.contains { pane in
            (content(pane)?.descriptor ?? entry.home.contents[pane])?.kind == PaneDescriptor.terminalKind
        }
    }

    private static func withoutFragment(_ address: String) -> String {
        guard var parts = URLComponents(string: address) else { return address }
        parts.fragment = nil
        return parts.string ?? address
    }
}
