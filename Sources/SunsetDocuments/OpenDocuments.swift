/// The documents that are open, for the whole app (R6; roadmap 0023 step M-b): asking for a place twice gives the same
/// document, so every pane on a file shows one text. A document stays while a pane holds it; when the last lets go it is
/// forgotten, with what was not saved (the sheet that asks first is step M-d).
@MainActor
public final class OpenDocuments {
    private var open: [DocumentPlace: OpenDocument] = [:]
    private let store: DocumentStore?

    /// - Parameter store: where stored documents are read and saved; nil when there is none in this run.
    public init(store: DocumentStore?) {
        self.store = store
    }

    public var all: [OpenDocument] { Array(open.values) }

    /// The open document at `place`, without holding it.
    public func document(at place: DocumentPlace) -> OpenDocument? { open[place.canonical] }

    /// The document at `place`, read if it is not open yet, and held: `close` it when the pane goes.
    /// - Complexity: O(the file's bytes) the first time (read and parsed on the caller's actor), O(1) after.
    public func open(_ place: DocumentPlace) -> OpenDocument {
        let place = place.canonical
        if let document = open[place] {
            document.holders += 1
            return document
        }
        let document: OpenDocument
        switch place {
            case .file(let path):
                document = OpenDocument(place: place, kind: DocumentKind(path: path), read: .read(path), store: nil)
                document.startWatching()
            case .stored(let id):
                let kind = store?.documents.first { $0.id == id }?.kind ?? .markdown
                var read = FileContent(problem: .missing)
                if let store {
                    do {
                        read = FileContent(text: try store.text(of: id))
                    } catch {
                        read.problem = error == .missing ? .missing : .unreadable
                    }
                }
                document = OpenDocument(place: place, kind: kind, read: read, store: store)
        }
        document.holders = 1
        open[place] = document
        return document
    }

    /// One pane lets go of `document`.
    public func close(_ document: OpenDocument) {
        document.holders -= 1
        guard document.holders <= 0 else { return }
        document.stopWatching()
        open[document.place] = nil
    }
}
