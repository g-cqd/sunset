internal import AemiIO
internal import Foundation
public import MarkdownLookKit
public import Observation
internal import SunsetHost

/// The document behind the panes that show it (R6; roadmap 0023 step M-b): one per file, or per stored document, for the
/// whole app, with one text, one undo history and one edited state (the kit's `MarkdownSource`), so that two panes can never
/// hold two unsaved versions. It saves (a file whole or not at all, with its permissions; a stored document into the store)
/// and it watches its file: a change on disk is taken when nothing was edited here, and merged block by block when something
/// was (step M-e): what only the disk changed is put in, what both changed is a conflict that waits for an answer.
@MainActor @Observable
public final class OpenDocument {
    public let place: DocumentPlace
    public let kind: DocumentKind
    /// The text, its undo history, and the page made from it.
    @ObservationIgnored public let source: MarkdownSource
    /// The rendered page, for the panes that show it.
    @ObservationIgnored public let page: DocumentPage
    public internal(set) var problem: OpenDocumentProblem?
    /// The file changed on disk while this text had edits, into something that cannot be merged (it is no longer text):
    /// neither was touched. Saving writes this text over it.
    public internal(set) var changedOnDisk = false
    /// The blocks changed both here and on disk that are not answered yet, in the order of the text.
    public internal(set) var conflicts: [DocumentConflict] = []
    /// What the last merge put in by itself, until it is dismissed, undone, or the file is saved.
    public internal(set) var lastMerge: DocumentMergeNotice?
    /// The file holds `base`, which the text's own count of what was saved does not know (a change on disk was merged):
    /// whether the text is edited is then told by comparing the two.
    var savedElsewhere = false
    /// Why a save nobody watched failed (by itself, or with every other at quit), until a save does or it is dismissed.
    public var saveFailure: String?

    @ObservationIgnored let store: DocumentStore?
    /// What the file held when it was last read or written here: a change on disk that says the same is not a change.
    @ObservationIgnored var known: FileContent.Mark?
    /// The text the file held then: what a change on disk and the edits made here are both compared with. Nil for a
    /// stored document, and for a file that was not read as text. One more copy of the file's text in memory.
    @ObservationIgnored var base: String?
    @ObservationIgnored var nextConflict = 0
    @ObservationIgnored var editObserver: (any NSObjectProtocol)?
    @ObservationIgnored var watcher: SunsetHost.FileWatcher?
    @ObservationIgnored var watching: Task<Void, Never>?
    /// How many panes hold it.
    @ObservationIgnored var holders = 0
    /// The documents of the app, which say when one saves itself.
    @ObservationIgnored weak var owner: OpenDocuments?
    /// The save that waits for its time.
    @ObservationIgnored var pendingSave: Task<Void, Never>?
    @ObservationIgnored var stoppedWatchingEdits = false
    /// Its edits were given up (Don't Save): it is forgotten with its last pane, edited as it is.
    @ObservationIgnored var givenUp = false

    init(place: DocumentPlace, kind: DocumentKind, read: FileContent, store: DocumentStore?) {
        self.place = place
        self.kind = kind
        self.store = store
        // A text file is shown as source only (R6): it is not read as Markdown.
        let content: MarkdownSource.Content = kind == .markdown ? .markdown : (kind == .mermaid ? .diagram : .plain)
        source = MarkdownSource(text: read.text, content: content)
        page = DocumentPage(source: source)
        problem = read.problem
        known = read.mark
        if case .file = place, read.problem == nil { base = read.text }
    }

    /// The text is not what the file, or the store, holds.
    /// - Complexity: O(1), but after a merge until the next save: then O(1) while the text is not as long as the file's, and
    ///   O(the text) when it is.
    public var isEdited: Bool {
        guard savedElsewhere, let base else { return source.isEdited }
        _ = source.revision
        return !source.storage.mutableString.isEqual(to: base)
    }
    /// How many panes hold it.
    public var paneCount: Int {
        holders
    }

    /// A file's name; a stored document's first heading or line (it follows the text).
    public var title: String {
        switch place {
            case .file(let path): return path.split(separator: "/").last.map(String.init) ?? path
            case .stored:
                _ = source.revision
                return DocumentTitle.of(source.text, kind: kind)
        }
    }

    /// Writes the text where the document lives. It is then no longer edited.
    public func save() throws(OpenDocumentFailure) {
        guard problem != .notText, problem != .unreadable else { throw .readOnly }
        guard conflicts.isEmpty else { throw .conflicts(conflicts.count) }
        let text = source.text
        switch place {
            case .file(let path):
                let data = Data(text.utf8)
                do {
                    try MarkdownLookKit.DocumentFile.write(data, to: URL(fileURLWithPath: path))
                } catch {
                    // The system's own words for it ("Permission denied"), without the path of the temporary file.
                    throw .write(unsafe String(cString: strerror(error.errno)))
                }
                known = FileContent.Mark(data)
                base = text
            case .stored(let id):
                guard let store else { throw .write("Sunset's own store is not open") }
                do {
                    try store.save(text, to: id)
                } catch {
                    throw .write("Sunset's own store did not take it")
                }
        }
        problem = nil
        changedOnDisk = false
        saveFailure = nil
        savedElsewhere = false
        lastMerge = nil
        source.markSaved()
    }
}
