public import Foundation

/// A Space as the session keeps it: what names it, its Favorites, its tabs in order, and what brings the content of each
/// pane of its tabs back (`PaneDescriptor`). The tabs have no selection of their own: each view of the Space has its own
/// (`SavedView`).
public struct SavedSpace: Sendable, Equatable, Codable {
    public var space: Space
    public var favorites: SavedFavorites
    public private(set) var tabs: Workspace
    public private(set) var contents: [PaneID: PaneDescriptor]

    public init(
        space: Space,
        favorites: SavedFavorites = SavedFavorites(),
        tabs: Workspace = Workspace(),
        contents: [PaneID: PaneDescriptor] = [:]
    ) {
        self.space = space
        self.favorites = favorites
        // No selection: what is compared and what is written are then the same thing.
        var plain = tabs
        plain.selectedID = nil
        plain.selectedEntry = nil
        self.tabs = plain
        let panes = Set(plain.allPanes)
        self.contents = contents.filter { panes.contains($0.key) }
    }

    /// Without the tabs that hold a pane of `taken` (a pane is in one place), and with the kept entries that claim one, or
    /// one of this Space's own tabs, not open. Returns the panes this Space then holds.
    mutating func settle(taken: Set<PaneID>) -> Set<PaneID> {
        var kept = tabs
        for item in tabs.items where !taken.isDisjoint(with: item.panes) { _ = kept.close(item: item.id) }
        kept.selectedID = nil
        tabs = kept
        let mine = Set(kept.allPanes)
        contents = contents.filter { mine.contains($0.key) }
        var entries = favorites.favorites
        var held = taken.union(mine)
        for entry in entries.entries {
            guard let panes = entry.open?.panes else { continue }
            if held.isDisjoint(with: panes) { held.formUnion(panes) } else { entries.unload(entry.id) }
        }
        favorites = SavedFavorites(favorites: entries, contents: favorites.contents)
        return held
    }

    /// `{"id", "name", "icon"?, "profile"?, "look"?, "favorites", "tabs": {"items"}, "contents": [{"pane", "kind", "state"}]}`.
    private enum Key: String, CodingKey { case favorites, tabs, contents }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let records = try container.decodeIfPresent([PaneContentRecord].self, forKey: .contents) ?? []
        self.init(
            space: try Space(from: decoder),
            // Favorites that cannot be read are none; tabs that cannot be read fail the Space, which is then left out.
            favorites: (try? container.decodeIfPresent(SavedFavorites.self, forKey: .favorites)) ?? SavedFavorites(),
            tabs: try container.decode(Workspace.self, forKey: .tabs),
            contents: PaneContentRecord.contents(of: records)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        try space.encode(to: encoder)
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(favorites, forKey: .favorites)
        try container.encode(tabs, forKey: .tabs)
        try container.encode(PaneContentRecord.records(of: contents, in: tabs.allPanes), forKey: .contents)
    }
}
