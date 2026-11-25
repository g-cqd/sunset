package import SunsetPane

/// An entry going from one set of kept entries to another: the Favorites and the Pinned grid.
extension FavoritesModel {
    /// Gives the entry `id` to `other` as it is: the same entry (its id, name, icon, command, home), and when it is open
    /// its content, still running, and the window that draws it. A window that shows it goes on showing it.
    /// - Parameters:
    ///   - id: an entry of this model (not a folder).
    ///   - other: where it goes.
    ///   - parent: the folder it goes in there; the top for nil.
    ///   - index: its place; the end for nil.
    /// - Returns: whether it went.
    package func give(
        _ id: Favorites.NodeID,
        to other: FavoritesModel,
        in parent: Favorites.NodeID? = nil,
        at index: Int? = nil
    ) -> Bool {
        guard other !== self, let entry = favorites.entry(id) else { return false }
        // Placed there first: when it cannot be, nothing was taken.
        var placed = false
        other.edit { placed = $0.insert(entry, in: parent, at: index) }
        guard placed else { return false }
        edit { _ = $0.takeEntry(id) }
        for pane in entry.open?.panes ?? [] {
            if let content = contents.removeValue(forKey: pane) {
                content.onExit = { [weak other] in other?.paneEnded(pane) }
                other.contents[pane] = content
            }
            if let waiting = pending.removeValue(forKey: pane) { other.pending[pane] = waiting }
        }
        if unconfirmed.remove(id) != nil { other.unconfirmed.insert(id) }
        if let owner = live.removeValue(forKey: id) { other.live[id] = owner }
        if let profile = openedProfile.removeValue(forKey: id) { other.openedProfile[id] = profile }
        return true
    }
}
