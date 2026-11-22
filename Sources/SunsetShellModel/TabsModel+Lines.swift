import SunsetPane

/// The sidebar's lines between its parts and the empty window's hint.
extension TabsModel {
    /// Which of the sidebar's lines are drawn.
    package struct SidebarLines: Equatable {
        package var afterPinned: Bool
        package var afterFavorites: Bool
    }

    /// A line is drawn under a part only when something is shown under it.
    package var linesShown: SidebarLines {
        let tabsShown = !workspace.isEmpty
        let favoritesShown = !favorites.isEmpty
        return SidebarLines(
            afterPinned: !pinnedEntries.isEmpty && (favoritesShown || tabsShown),
            afterFavorites: favoritesShown && tabsShown
        )
    }

    /// What the empty window says.
    package var emptyHint: String {
        scopes.terminal ? "No tab. \u{2318}T for a terminal" : "No tab. \u{2318}T to open one"
    }
}
