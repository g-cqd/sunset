package import SunsetPane

/// A window and the scopes of the app that are off (roadmap 0033; ADR-0056).
extension TabsModel {
    /// The entries of the Favorites this window lists, at any depth: those of a scope that is off are hidden.
    package var shownFavorites: [Favorites.Entry] { favorites.favorites.entries.filter(scopes.allows) }

    /// Whether a kept entry is listed and can be opened here.
    package func shows(_ entry: Favorites.Entry) -> Bool { scopes.allows(entry) }

    /// The scopes changed: a kept entry of one that went off is no longer shown here.
    func scopesChanged() {
        sections.settle(for: scopes)
        // The panel opposite the tabs with no section left to show is closed.
        if showsHistory, SidebarSection.panel(for: scopes).isEmpty { showsHistory = false }
        guard let shown = shownEntry, !scopes.allows(shown) else { return }
        left(shown.id)
        selectedEntry = nil
        syncStates()
    }
}
