/// What a document is: Markdown, a Mermaid diagram, or plain text.
public enum DocumentKind: String, Sendable, Codable, CaseIterable {
    case markdown, mermaid, text

    /// The extension of its file when it leaves the store.
    public var fileExtension: String {
        switch self {
            case .markdown: "md"
            case .mermaid: "mmd"
            case .text: "txt"
        }
    }
}
