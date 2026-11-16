public import Foundation

/// A window as the session keeps it since Spaces (ADR-0045): a view of a Space, with the tab or the kept entry it had
/// selected. The tabs are the Space's; nothing of them is the window's.
public struct SavedView: Sendable, Equatable, Codable {
    public var space: Space.ID
    /// The tab it showed; nil for none (a window that was opened and chose nothing, or one that showed a kept entry only).
    public var selected: Workspace.ItemID?
    /// The kept entry it showed instead of a tab.
    public var entry: Favorites.NodeID?

    public init(space: Space.ID, selected: Workspace.ItemID? = nil, entry: Favorites.NodeID? = nil) {
        self.space = space
        self.selected = selected
        self.entry = entry
    }
}
