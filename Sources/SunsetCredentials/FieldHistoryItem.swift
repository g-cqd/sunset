public import Foundation

/// One previous value of a secret field, recorded automatically whenever the value changes (roadmap 0092 D).
public struct FieldHistoryItem: Hashable, Sendable, Codable {
    public var value: String
    public var changedAt: Date

    public init(value: String, changedAt: Date) {
        self.value = value
        self.changedAt = changedAt
    }
}
