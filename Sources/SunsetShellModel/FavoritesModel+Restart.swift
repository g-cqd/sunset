internal import SunsetPane

/// Reloading kept entries when their Space changes profile or moves across profiles.
extension FavoritesModel {
    /// Stops every open entry containing a pane of `kind` (non-private) so it reopens fresh under the current Space's
    /// profile, clearing any stale Reload-As `"as"` override on its home descriptors.
    package func restart(kind: String) {
        let affected = favorites.entries.filter { entry in
            guard let open = entry.open else { return false }
            return open.panes.contains { pane in
                if let content = contents[pane] {
                    return content.descriptor.kind == kind && !content.isPrivate
                }
                if let waiting = pending[pane] {
                    return waiting.kind == kind && waiting.state["private"] != "1"
                }
                return false
            }
        }
        for entry in affected {
            unload(entry.id)
            var updated = entry.home.contents
            var changed = false
            for (pane, descriptor) in updated where descriptor.kind == kind && descriptor.state["as"] != nil {
                var stripped = descriptor
                stripped.state["as"] = nil
                updated[pane] = stripped
                changed = true
            }
            if changed {
                let home = Favorites.Home(
                    layout: entry.home.layout,
                    focused: entry.home.focused,
                    contents: updated
                )
                edit { $0.setHome(home, for: entry.id) }
            }
        }
    }
}
