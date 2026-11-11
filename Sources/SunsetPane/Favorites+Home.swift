import Foundation

extension Favorites.Home: Codable {
    private enum Key: String, CodingKey { case layout, focused, contents }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let records = try container.decodeIfPresent([PaneContentRecord].self, forKey: .contents) ?? []
        self.init(
            layout: try container.decode(SplitLayout.self, forKey: .layout),
            focused: try container.decode(PaneID.self, forKey: .focused),
            contents: PaneContentRecord.contents(of: records)
        )
        guard holdsTogether else {
            throw DecodingError.dataCorruptedError(
                forKey: .layout,
                in: container,
                debugDescription: "a home that does not hold together"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(layout, forKey: .layout)
        try container.encode(focused, forKey: .focused)
        try container.encode(PaneContentRecord.records(of: contents, in: layout.panes), forKey: .contents)
    }
}
