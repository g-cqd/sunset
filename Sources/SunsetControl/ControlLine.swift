public import Foundation

/// A request or a reply as a line: compact JSON and a newline. A line longer than `limit` is not read.
public enum ControlLine {
    /// The most bytes a line may have.
    public static let limit = 1 << 20

    public static func encode(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(value)
        data.append(0x0A)
        return data
    }

    public static func decode<Value: Decodable>(_ type: Value.Type, from line: Data) throws -> Value {
        try JSONDecoder().decode(type, from: line)
    }
}
