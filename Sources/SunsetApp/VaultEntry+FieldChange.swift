import Foundation
import SunsetCredentials

extension VaultEntry {
    /// A field's sheet saved (t334).
    mutating func apply(_ change: FieldChange, to field: UUID) {
        apply(name: change.name, kind: change.kind, secret: change.secret, keepingOld: change.keepingOld, to: field)
    }
}
