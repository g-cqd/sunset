public import Foundation

/// One sealed file attachment stored inside a vault entry (roadmap 0092 C): bounded in size so records remain fast
/// to open and seal atomically inside the vault's SQLite blob.
public struct VaultAttachment: Hashable, Sendable, Codable, Identifiable {
    /// Maximum size of a single attachment (4 MiB).
    public static let maxBytes = 4 << 20

    public var id: UUID
    public var filename: String
    public var contentType: String
    public var data: Data
    public var addedAt: Date

    public init(
        id: UUID = UUID(),
        filename: String,
        contentType: String = "application/octet-stream",
        data: Data,
        addedAt: Date
    ) {
        self.id = id
        self.filename = filename
        self.contentType = contentType
        self.data = data
        self.addedAt = addedAt
    }
}
