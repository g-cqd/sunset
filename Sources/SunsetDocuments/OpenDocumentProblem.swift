/// What is wrong with where a document comes from; its text is still shown.
public enum OpenDocumentProblem: Sendable, Equatable {
    /// No file, or no such document in the store: saving makes the file.
    case missing
    /// It is there and could not be read.
    case unreadable
    /// The file is not UTF-8 text: shown as well as it can be, and never saved over.
    case notText
}
