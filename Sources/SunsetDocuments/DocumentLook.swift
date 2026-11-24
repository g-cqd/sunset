public import MarkdownLookKit
public import Observation

/// How documents look, from the settings: what source and rendered panes read, so a change shows at once.
@MainActor
@Observable
public final class DocumentLook {
    /// A heading's text at the page's size for its level (`documents.largerHeadings`).
    public var largerHeadings = true
    /// A plain click on a link opens it beside the document, not in a new tab (`documents.linksOpen`).
    public var linksBeside = false
    /// Markdown rendering settings (`documents.*`), mirrored to `OpenDocument.source.settings` and to the shared
    /// Quick Look preferences domain.
    public var viewer = ViewerSettings()

    public init() {}
}
