import Foundation

extension Favorites.Folder: Codable {
    private enum Key: String, CodingKey { case id, name, icon, collapsed, children }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        self.init(
            id: try container.decode(Favorites.NodeID.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            icon: try container.decodeIfPresent(PaneIcon.self, forKey: .icon),
            isCollapsed: try container.decodeIfPresent(Bool.self, forKey: .collapsed) ?? false,
            children: try container.decodeIfPresent([Favorites.Node.Lossy].self, forKey: .children)?.compactMap(\.value)
                ?? []
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encode(isCollapsed, forKey: .collapsed)
        try container.encode(children, forKey: .children)
    }
}
