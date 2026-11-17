public import Observation

/// How the documents' source looks, from the settings: what a source pane reads, so a change shows at once (roadmap 0034).
@MainActor
@Observable
public final class DocumentLook {
    /// A heading's text at the page's size for its level (`documents.largerHeadings`).
    public var largerHeadings = true

    public init() {}
}
