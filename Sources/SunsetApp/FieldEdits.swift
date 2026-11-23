import SunsetCredentials

/// What the page does with a field's sheet once saved.
struct FieldEdits: Sendable {
    let apply: @MainActor @Sendable (FieldChange) -> Void
}
