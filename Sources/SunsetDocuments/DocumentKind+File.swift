/// A file's kind, by its name (Markdown, Mermaid, a page, and any other file as text).
extension DocumentKind {
    /// - Parameter path: the file's path or name.
    public init(path: String) {
        let name = path.split(separator: "/").last.map(String.init) ?? path
        let parts = name.split(separator: ".", omittingEmptySubsequences: false)
        let last = parts.count > 1 ? parts[parts.count - 1].lowercased() : ""
        switch last {
            case "md", "markdown", "mdown", "mkd", "mkdn", "mdwn": self = .markdown
            case "mmd", "mermaid": self = .mermaid
            case "html", "htm", "xhtml", "svg": self = .page
            default: self = .text
        }
    }

    /// Whether Sunset opens the file at `path` as a document rather than handing it to the Mac: what it draws (Markdown,
    /// Mermaid, pages) and the text files people read in a terminal's links (source code, configuration, logs).
    public static func opens(path: String) -> Bool {
        let name = path.split(separator: "/").last.map(String.init) ?? path
        guard let dot = name.lastIndex(of: "."), dot != name.startIndex else { return false }
        let last = name[name.index(after: dot)...].lowercased()
        return Self(path: path) != .text || textExtensions.contains(last)
    }

    private static let textExtensions: Set<String> = Set(
        "txt swift json toml yaml yml sh zsh bash py js ts css xml rs c h cpp hpp go rb log csv tsv ini conf"
            .split(separator: " ").map(String.init)
    )
}
