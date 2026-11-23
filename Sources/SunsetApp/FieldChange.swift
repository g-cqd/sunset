import SunsetCredentials

/// A field's name, kind and secrecy, as its editing sheet saves them (t334); `keepingOld`: a value that does not fit the new
/// kind is moved to a new field beside it.
struct FieldChange: Sendable, Equatable {
    var name: String
    var kind: FieldKind
    var secret: Bool
    var keepingOld = false
}
