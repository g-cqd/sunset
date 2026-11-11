import Foundation

extension Favorites.Node: Codable {
    private enum Key: String, CodingKey { case kind }

    /// A node that fails to read is nil instead of failing the tree.
    struct Lossy: Decodable {
        let value: Favorites.Node?
        init(from decoder: any Decoder) throws { value = try? Favorites.Node(from: decoder) }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        switch try container.decode(String.self, forKey: .kind) {
            case "folder": self = .folder(try Favorites.Folder(from: decoder))
            case "entry": self = .entry(try Favorites.Entry(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "a node that is neither a folder nor an entry"
                )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
            case .folder(let folder):
                try container.encode("folder", forKey: .kind)
                try folder.encode(to: encoder)
            case .entry(let entry):
                try container.encode("entry", forKey: .kind)
                try entry.encode(to: encoder)
        }
    }
}
