package import AppKit
package import SunsetPane

/// A kept page away from where it was kept (the owner's note n3): its row says so, and a double click takes it back.
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

    /// A click on a Pinned tile, the `count`th of a run (the event's click count: a tile is a button, which takes the clicks
    /// before a gesture beside it could count two; n7): the first shows it, the second is a double click.
    /// The second of two clicks on the same tile within the system's double-click time is a double click too, whatever the
    /// event says (the owner, 2026-11-18, the second report: the button under a drag does not always see a count of two).
    package func clickTile(
        entry id: Favorites.NodeID,
        count: Int,
        at time: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        let quick = lastTileClick.map { $0.entry == id && time - $0.time <= Self.doubleClickTime } ?? false
        if count >= 2 || quick {
            lastTileClick = nil
            return doubleClick(entry: id)
        }
        lastTileClick = (id, time)
        select(entry: id)
    }

    /// The system's double-click time.
    package static var doubleClickTime: TimeInterval { NSEvent.doubleClickInterval }

    /// Whether a kept entry has a terminal among its panes, live or saved: only then has it a command to edit or run (the
    /// owner's note n8).
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
