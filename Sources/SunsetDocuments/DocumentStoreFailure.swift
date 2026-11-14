/// Why the store could not do what was asked.
public enum DocumentStoreFailure: Error, Sendable, Equatable {
    /// No such document.
    case missing
    /// Its file does not open (damaged, or sealed with another key).
    case unreadable
    /// It could not be written, or put away: the document is as it was.
    case write
}
