public import Observation

/// How the documents' source looks, from the settings: what a source pane reads, so a change shows at once (roadmap 0034).
@MainActor
@Observable
public final class DocumentLook {
    /// A heading's text at the page's size for its level (`documents.largerHeadings`).
    public var largerHeadings = true
    /// A plain click on a link opens it beside the document, not in a new tab (`documents.linksOpen`).
    public var linksBeside = false

    public init() {}
}
