public import Foundation

/// The panes of the entries that are open: the same edits a window's tabs have (`Workspace+Splits`).
extension Favorites {
    /// Gives the keyboard, within its entry, to a pane.
    public mutating func focus(pane: PaneID) {
        guard let id = entry(containing: pane)?.id else { return }
        updateEntry(id) { $0.open?.focused = pane }
    }

    /// A new pane on `edge` of `target`, in the entry that holds `target`, focused; nil when no open entry holds it.
    @discardableResult
    public mutating func addPane(beside target: PaneID, edge: PaneEdge) -> PaneID? {
        guard let id = entry(containing: target)?.id else { return nil }
        let pane = PaneID()
        updateEntry(id) { entry in
            entry.open?.insert(.pane(pane), beside: target, edge: edge)
            entry.open?.focused = pane
        }
        return pane
    }

    /// Closes one pane of an open entry. With its only pane the entry is unloaded, and kept: true then.
    @discardableResult
    public mutating func close(pane: PaneID) -> Bool {
        guard let id = entry(containing: pane)?.id else { return false }
        var unloaded = false
        updateEntry(id) { entry in
            if entry.open?.remove(pane) != true {
                entry.open = nil
                unloaded = true
            }
        }
        return unloaded
    }

    /// Sets how the split at `path` divides its space, in the open entry `id`.
    public mutating func setRatio(_ ratio: Double, at path: [SplitBranch], in id: NodeID) {
        updateEntry(id) { entry in
            guard let layout = entry.open?.layout else { return }
            entry.open?.layout = layout.settingRatio(ratio, at: path)
        }
    }
}
