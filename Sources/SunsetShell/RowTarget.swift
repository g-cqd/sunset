package import SunsetPane

/// What can be renamed or given an icon in the sidebar: a tab, a node of the Favorites (an entry or a folder), or a Space
/// (its icon in the row at the bottom).
package enum RowTarget: Hashable, Sendable {
    case tab(Workspace.ItemID)
    case node(Favorites.NodeID)
    case space(Space.ID)
}
