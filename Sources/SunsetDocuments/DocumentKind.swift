/// What a document is: Markdown, a Mermaid diagram, a page (HTML, XHTML, SVG: drawn by WebKit), or plain text.
public enum DocumentKind: String, Sendable, Codable, CaseIterable {
    case markdown, mermaid, page, text

    /// The extension of its file when it leaves the store.
    public var fileExtension: String {
        switch self {
            case .markdown: "md"
            case .mermaid: "mmd"
            case .page: "html"
            case .text: "txt"
        }
    }
}
