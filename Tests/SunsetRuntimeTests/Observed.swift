import Foundation

/// A key-value observable value for `KeyValueProbe`.
final class Observed: NSObject, @unchecked Sendable {
    @objc dynamic var number = 0
}
