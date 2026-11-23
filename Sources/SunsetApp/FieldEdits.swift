import SunsetCredentials

/// What the page lets a field's row change of it while the entry is edited (n101–n104): its name, its kind, whether it is
/// secret.
struct FieldEdits {
    let rename: (String) -> Void
    let setKind: (FieldKind) -> Void
    let markSecret: (Bool) -> Void
}
