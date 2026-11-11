import Foundation

/// `{"symbol": "server.rack", "color"?: "#RRGGBB"}` or `{"emoji": "📁"}`: written by hand, so that the saved form is not the compiler's.
extension PaneIcon: Codable {
    private enum Key: String, CodingKey { case symbol, emoji, color }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        if let name = try container.decodeIfPresent(String.self, forKey: .symbol) {
            // A colour that does not read is no colour, not a broken icon.
            let color = (try? container.decodeIfPresent(String.self, forKey: .color))
                .flatMap { $0.flatMap(IconColor.init(hex:)) }
            self = .symbol(name, color: color)
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
            case .symbol(let name, let color):
                try container.encode(name, forKey: .symbol)
                try container.encodeIfPresent(color?.hex, forKey: .color)
            case .emoji(let emoji): try container.encode(emoji, forKey: .emoji)
        }
    }
}
