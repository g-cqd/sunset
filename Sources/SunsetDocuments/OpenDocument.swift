internal import AemiIO
internal import Foundation
public import MarkdownLookKit
public import Observation
internal import SunsetHost

/// The document behind the panes that show it (R6; roadmap 0023 step M-b): one per file, or per stored document, for the
/// whole app, with one text, one undo history and one edited state (the kit's `MarkdownSource`), so that two panes can never
/// hold two unsaved versions. It saves (a file whole or not at all, with its permissions; a stored document into the store)
/// and it watches its file: a change on disk is taken when nothing was edited here, and kept apart and said when something was.
@MainActor @Observable
public final class OpenDocument {
    public let place: DocumentPlace
    public let kind: DocumentKind
    /// The text, its undo history, and the page made from it.
    @ObservationIgnored public let source: MarkdownSource
    /// The rendered page, for the panes that show it.
    @ObservationIgnored public let page: DocumentPage
    public internal(set) var problem: OpenDocumentProblem?
    /// The file changed on disk while this text had edits: neither was touched. Saving writes this text over it.
    public internal(set) var changedOnDisk = false

    @ObservationIgnored let store: DocumentStore?
    /// What the file held when it was last read or written here: a change on disk that says the same is not a change.
    @ObservationIgnored var known: FileContent.Mark?
    @ObservationIgnored var watcher: SunsetHost.FileWatcher?
    @ObservationIgnored var watching: Task<Void, Never>?
    /// How many panes hold it.
    @ObservationIgnored var holders = 0

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
    }

    public var isEdited: Bool { source.isEdited }
    /// How many panes hold it.
    public var paneCount: Int { holders }

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
        source.markSaved()
    }
}
