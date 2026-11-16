/// Why a document could not be saved: its text is as it was, and still edited.
public enum OpenDocumentFailure: Error, Sendable, Equatable {
    /// What was read is not text Sunset can write back as it was.
    case readOnly
    /// The file, or the store, could not be written.
    case write(String)
    /// Blocks changed here and on disk are not answered yet (step M-e): this many. Nothing is written until they are.
    case conflicts(Int)

    /// The sentence a pane shows for it.
    public var sentence: String {
        switch self {
            case .readOnly: "This document was not read, so it is not written."
            case .write(let reason): "Not saved: \(reason)."
            case .conflicts(1): "Not saved: one block changed both here and on disk. Choose which to keep."
            case .conflicts(let count):
                "Not saved: \(count) blocks changed both here and on disk. Choose which to keep."
        }
    }
}
