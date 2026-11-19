/// The documents that are open, for the whole app (R6; roadmap 0023 step M-b): asking for a place twice gives the same
/// document, so every pane on a file shows one text. A document stays while a pane holds it; when the last lets go it is
/// forgotten, unless it has edits nobody gave up (step M-d): what closes a pane asks first, a document of the store is kept
/// as it is, and edits that got past both stay here, held by no pane, until they are saved, given up, or named at quit.
@MainActor
public final class OpenDocuments {
    private var open: [DocumentPlace: OpenDocument] = [:]
    private let store: DocumentStore?
    /// When a document saves itself (the settings; both off for files by default).
    public var autosave = DocumentAutosave()
    /// How their source looks (the settings).
    public let look = DocumentLook()

    /// - Parameter store: where stored documents are read and saved; nil when there is none in this run.
    public init(store: DocumentStore?) {
        self.store = store
    }

    public var all: [OpenDocument] {
        Array(open.values)
    }

    /// The open document at `place`, without holding it.
    public func document(at place: DocumentPlace) -> OpenDocument? {
        open[place.canonical]
    }

    /// The document at `place`, read if it is not open yet, and held: `close` it when the pane goes.
    /// - Complexity: O(the file's bytes) the first time (read and parsed on the caller's actor), O(1) after.
    public func open(_ place: DocumentPlace) -> OpenDocument {
        let place = place.canonical
        if let document = open[place] {
            document.holders += 1
            document.givenUp = false
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
        document.owner = self
        document.watchEdits()
        open[place] = document
        return document
    }

    /// The app stopped being the one typed in: every document that saves itself then does.
    public func focusLost() {
        for document in open.values { document.focusLost() }
    }

    /// Quitting: every document of the store is kept as it is. A file's edits are asked about, not written here.
    public func keepStored() {
        for document in open.values where document.isStored { document.saveItself() }
    }

    /// The documents with edits that are not saved, by title: the ones a pane shows and the ones none does any more.
    public var edited: [OpenDocument] {
        open.values.filter(\.isEdited).sorted { $0.title < $1.title }
    }

    /// Quitting, Save All: every edited document is written.
    /// - Returns: the ones that could not be, each saying why (`saveFailure`).
    public func saveAll() -> [OpenDocument] {
        var failed: [OpenDocument] = []
        for document in edited {
            do throws(OpenDocumentFailure) {
                try document.save()
            } catch {
                document.saveFailure = error.sentence
                failed.append(document)
            }
        }
        return failed
    }

    /// The person gave up the edits of `document` (Don't Save): it is forgotten with its last pane, at once if it has none.
    public func discard(_ document: OpenDocument) {
        document.givenUp = true
        if document.holders <= 0 { forget(document) }
    }

    /// One pane lets go of `document`.
    public func close(_ document: OpenDocument) {
        document.holders = max(0, document.holders - 1)
        guard document.holders == 0 else { return }
        if document.isStored, !document.givenUp { document.saveItself() }
        guard !document.isEdited || document.givenUp else { return }
        forget(document)
    }

    private func forget(_ document: OpenDocument) {
        document.stopAutosaving()
        document.stopWatching()
        document.stopFollowingEdits()
        open[document.place] = nil
    }
}
