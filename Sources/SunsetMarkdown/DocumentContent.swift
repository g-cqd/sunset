internal import Foundation
package import MarkdownLookKit
package import Observation
package import SunsetDocuments
package import SunsetPane
package import SunsetShell
package import SwiftUI

/// A document in a pane (R6; roadmap 0023 step M-c): Markdown or a Mermaid diagram drawn natively or shown as source, any
/// other text as source. The pane holds no text: it is a view of the app's one `OpenDocument` for the file, so a second pane
/// on the same file shows the same text, edits and undo history.
@MainActor @Observable
package final class DocumentContent: PaneContent {
    package static let kind = PaneDescriptor.documentKind

    package let document: OpenDocument
    package private(set) var mode: DocumentMode
    /// The size of the source editor's text; the page's is the document's (`settings.textSize`), and they move together.
    package private(set) var fontSize = Double(ViewerSettings.defaultTextSize)
    /// Why the last save did not happen, until it is dismissed or a save does.
    package var failure: String?
    /// The conflict this pane is on (its id), while it waits for an answer.
    package internal(set) var shownConflict: Int?
    /// Counts each time a conflict is to be brought into view: the views follow it.
    package internal(set) var reveal = 0
    /// The handle on this pane's editor: its focus, and later its commands.
    @ObservationIgnored package let proxy = MarkdownEditorProxy()
    @ObservationIgnored package var onExit: () -> Void = {}
    @ObservationIgnored package var onFocusRequest: () -> Void = {}
    /// Something the session keeps has changed (which view).
    @ObservationIgnored package var onChange: () -> Void = {}
    @ObservationIgnored package var onOpen: (DocumentOpening) -> Void = { _ in }
    @ObservationIgnored let documents: OpenDocuments
    @ObservationIgnored private var isVisible = false
    @ObservationIgnored private var hadFocus = false
    @ObservationIgnored private var stopped = false

    /// The pane a saved descriptor says; nil when it names no document.
    package convenience init?(_ descriptor: PaneDescriptor, documents: OpenDocuments) {
        guard let place = DocumentPlace(state: descriptor.state) else { return nil }
        let wanted = descriptor.state["view"].flatMap(DocumentMode.init(rawValue:))
        self.init(document: documents.open(place), mode: wanted, documents: documents)
    }

    /// A pane on `document`, which the caller has opened for it (it is closed when the pane stops).
    init(document: OpenDocument, mode: DocumentMode?, documents: OpenDocuments) {
        self.document = document
        self.documents = documents
        // With no view asked for: an empty document has nothing to draw, it opens ready to type.
        let unasked: DocumentMode = document.source.storage.length == 0 ? .source : .rendered
        self.mode = document.kind == .text ? .source : (mode ?? unasked)
    }

    /// What brings a pane on the file at `path` back.
    package static func descriptor(file path: String) -> PaneDescriptor {
        PaneDescriptor(kind: kind, state: DocumentPlace.file(path).state)
    }

    // MARK: PaneContent

    package var title: String { document.title }
    package var detail: String? {
        guard case .file(let path) = document.place else { return nil }
        return (path as NSString).deletingLastPathComponent
    }
    package var glyph: PaneGlyph { .symbol(PaneDescriptor.documentSymbol) }
    package var progress: Double? { nil }
    package var isEdited: Bool { document.isEdited }
    /// Nothing runs in a document: its edits are asked about in a sheet (`unsaved`), not by the red tab of a busy terminal.
    package var closeWarning: String? { nil }
    package var descriptor: PaneDescriptor {
        var state = document.place.state
        state["view"] = mode.rawValue
        state["title"] = title
        return PaneDescriptor(kind: Self.kind, state: state)
    }

    package func setState(focused: Bool, visible: Bool) {
        guard !stopped else { return }
        isVisible = visible
        // Another pane took the keyboard: the document saves itself when the setting says so.
        if hadFocus, !focused { document.focusLost() }
        hadFocus = focused
        tellPage()
        if focused, visible, mode == .source { proxy.focus() }
    }

    package func stop() {
        guard !stopped else { return }
        stopped = true
        document.page.setInterest(nil, of: self)
        documents.close(document)
    }

    package func makeView(_ context: PaneViewContext) -> AnyView {
        AnyView(DocumentPaneView(content: self, context: context))
    }

    // MARK: The view

    /// Whether the document has a page at all: a text file is source only.
    package var canRender: Bool { document.kind != .text }

    /// From the page to the source and back (Cmd-Shift-E).
    package func toggleMode() {
        guard canRender else { return }
        mode = mode.other
        tellPage()
        onChange()
    }

    /// The page is wanted while this pane shows it: made while it is on screen, kept while its tab is not.
    private func tellPage() {
        document.page.setInterest(mode == .rendered && canRender ? isVisible : nil, of: self)
    }

    /// Bigger or smaller text, in the page and in the source.
    package func zoom(by steps: Int) {
        document.source.settings.textSize += steps
        fontSize = Double(document.source.settings.textSize)
    }

    package func resetZoom() {
        document.source.settings.textSize = ViewerSettings.defaultTextSize
        fontSize = Double(ViewerSettings.defaultTextSize)
    }
}
