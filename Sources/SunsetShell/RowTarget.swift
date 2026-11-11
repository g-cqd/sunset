package import SunsetPane

/// A row of the sidebar that can be renamed or given an icon: a window's tab, or a node of the Favorites (an entry or a folder).
package enum RowTarget: Hashable, Sendable {
    case tab(Workspace.ItemID)
    case node(Favorites.NodeID)
}
