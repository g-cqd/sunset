internal import AemiJSONCore
internal import OrderedCollections

/// A JSON text as a tree to fold: each node its key (or index), its value said in a line for a scalar, its children for an
/// object or an array, in the file's order. Nil when the text is not JSON.
public struct DataTree: Sendable, Equatable, Identifiable {
    public enum Value: Sendable, Equatable {
        case object(count: Int)
        case array(count: Int)
        case string(String)
        case number(String)
        case bool(Bool)
        case null
    }

    /// Its path from the root ("$", "$.items[2]"): unique in the tree.
    public let id: String
    public let key: String
    public let value: Value
    /// Nil for a scalar (nothing to fold).
    public let children: [DataTree]?

    /// - Complexity: O(the text).
    public init?(_ text: String) {
        guard let root = try? JSONValue(parsing: text, options: JSONParseOptions(validation: .json5)) else {
            return nil
        }
        self.init(root, key: "$", path: "$")
    }

    private init(_ json: JSONValue, key: String, path: String) {
        id = path
        self.key = key
        switch json {
            case .object(let members):
                value = .object(count: members.count)
                children = members.map { name, member in DataTree(member, key: name, path: path + "." + name) }
            case .array(let items):
                value = .array(count: items.count)
                children = items.enumerated()
                    .map { index, item in DataTree(item, key: "\(index)", path: path + "[\(index)]") }
            case .string(let text):
                value = .string(text)
                children = nil
            case .int(let number):
                value = .number(String(number))
                children = nil
            case .number(let number):
                value = .number(String(number))
                children = nil
            case .bool(let flag):
                value = .bool(flag)
                children = nil
            default:
                value = .null
                children = nil
        }
    }
}
