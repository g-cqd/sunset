/// Why a document could not be saved: its text is as it was, and still edited.
public enum OpenDocumentFailure: Error, Sendable, Equatable {
    /// What was read is not text Sunset can write back as it was.
    case readOnly
    /// The file, or the store, could not be written.
    case write(String)

    /// The sentence a pane shows for it.
    public var sentence: String {
        switch self {
            case .readOnly: "This document was not read, so it is not written."
            case .write(let reason): "Not saved: \(reason)."
        }
    }
}
