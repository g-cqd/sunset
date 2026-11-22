public import Foundation

/// A document that lives in Sunset, as the library shows it: what the index holds of it. Its text is in its own sealed
/// file.
public struct StoredDocument: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public var title: String
    public var kind: DocumentKind
    public var created: Date
    public var modified: Date
    /// The sealed file's size and modification time when this was written: the index follows a file that no longer matches.
    var size: Int
    var stamp: Double
}
