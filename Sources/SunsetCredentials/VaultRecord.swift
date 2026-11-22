/// What one sealed record of a vault holds: an entry or one of the person's templates (ADR-0092). The kind is inside the
/// seal: the file says nothing of what a record is.
enum VaultRecord: Codable, Equatable {
    case entry(VaultEntry)
    case template(EntryTemplate)
    /// The sites the person said never to offer saving for.
    case neverSave([String])
}
