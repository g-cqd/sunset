public import Foundation

/// The Favorites as they were left, and what brings the content of the panes that were live back (`PaneDescriptor`); what an entry starts from is in the
/// entry itself. A live pane with nothing saved is a new terminal.
public struct SavedFavorites: Sendable, Equatable, Codable {
    public var favorites: Favorites
    public var contents: [PaneID: PaneDescriptor]

    public init(favorites: Favorites = Favorites(), contents: [PaneID: PaneDescriptor] = [:]) {
        self.favorites = favorites
        // Only the panes that are live: what is compared and what is written are then the same thing.
        let live = Set(favorites.livePanes)
        self.contents = contents.filter { live.contains($0.key) }
    }

    private enum Key: String, CodingKey { case favorites, contents }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let records = try container.decodeIfPresent([PaneContentRecord].self, forKey: .contents) ?? []
        self.init(
            favorites: try container.decode(Favorites.self, forKey: .favorites),
            contents: PaneContentRecord.contents(of: records)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(favorites, forKey: .favorites)
        try container.encode(PaneContentRecord.records(of: contents, in: favorites.livePanes), forKey: .contents)
    }
}
