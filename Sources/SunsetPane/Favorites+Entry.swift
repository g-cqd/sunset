import Foundation

extension Favorites.Entry: Codable {
    private enum Key: String, CodingKey { case id, title, icon, home, open, command, commandSeal }

    /// The live tab of an open entry.
    private struct Live: Codable {
        let id: Workspace.ItemID
        let layout: SplitLayout
        let focused: PaneID

        /// The tab, when it holds together: its focused pane is one of its panes and no pane is there twice.
        var item: Workspace.Item? {
            let panes = layout.panes
            guard panes.contains(focused), Set(panes).count == panes.count else { return nil }
            return Workspace.Item(id: id, layout: layout, focused: focused)
        }
    }

    /// A live tab that does not hold together is read as an entry that is not open; a home that does not is not an entry.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        self.init(
            id: try container.decode(Favorites.NodeID.self, forKey: .id),
            title: try container.decodeIfPresent(String.self, forKey: .title),
            icon: try container.decodeIfPresent(PaneIcon.self, forKey: .icon),
            home: try container.decode(Favorites.Home.self, forKey: .home),
            open: (try? container.decodeIfPresent(Live.self, forKey: .open))?.item
        )
        command = try container.decodeIfPresent(String.self, forKey: .command)
        commandSeal = try container.decodeIfPresent(String.self, forKey: .commandSeal)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encode(home, forKey: .home)
        try container.encodeIfPresent(
            open.map { Live(id: $0.id, layout: $0.layout, focused: $0.focused) },
            forKey: .open
        )
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(commandSeal, forKey: .commandSeal)
    }
}
