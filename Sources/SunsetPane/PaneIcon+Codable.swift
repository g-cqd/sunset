import Foundation

/// `{"symbol": "server.rack"}` or `{"emoji": "📁"}`: written by hand, so that the saved form is not the compiler's.
extension PaneIcon: Codable {
    private enum Key: String, CodingKey { case symbol, emoji }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        if let name = try container.decodeIfPresent(String.self, forKey: .symbol) {
            self = .symbol(name)
        } else if let emoji = try container.decodeIfPresent(String.self, forKey: .emoji) {
            self = .emoji(emoji)
        } else {
            let path = decoder.codingPath
            let context = DecodingError.Context(codingPath: path, debugDescription: "neither symbol nor emoji")
            throw DecodingError.dataCorrupted(context)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
            case .symbol(let name): try container.encode(name, forKey: .symbol)
            case .emoji(let emoji): try container.encode(emoji, forKey: .emoji)
        }
    }
}
