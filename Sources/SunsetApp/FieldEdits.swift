import SunsetCredentials

/// What the page lets a field's row change of it while the entry is edited (n101–n104): its name, its kind, whether it is
/// secret.
struct FieldEdits: Sendable {
    let rename: @MainActor @Sendable (String) -> Void
    let setKind: @MainActor @Sendable (FieldKind) -> Void
    let markSecret: @MainActor @Sendable (Bool) -> Void
}
