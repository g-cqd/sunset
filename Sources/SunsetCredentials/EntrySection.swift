public import Foundation

/// A named group of an entry's fields, in their order.
public struct EntrySection: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var fields: [EntryField]

    public init(id: UUID = UUID(), name: String, fields: [EntryField] = []) {
        self.id = id
        self.name = name
        self.fields = fields
    }
}
