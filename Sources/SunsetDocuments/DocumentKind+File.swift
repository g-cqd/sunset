/// A file's kind, by its name (Markdown, Mermaid, and any other file as text).
extension DocumentKind {
    /// - Parameter path: the file's path or name.
    public init(path: String) {
        let name = path.split(separator: "/").last.map(String.init) ?? path
        let parts = name.split(separator: ".", omittingEmptySubsequences: false)
        let last = parts.count > 1 ? parts[parts.count - 1].lowercased() : ""
        switch last {
            case "md", "markdown", "mdown", "mkd", "mkdn", "mdwn": self = .markdown
            case "mmd", "mermaid": self = .mermaid
            default: self = .text
        }
    }
}
