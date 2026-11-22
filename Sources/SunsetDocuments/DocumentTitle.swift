/// What a document that lives in Sunset is called (from its content, no name of its own to manage): its first heading for
/// Markdown, else its first line with something on it, else "Untitled". It changes as the text does.
public enum DocumentTitle {
    /// Characters kept of a long first line.
    public static let limit = 80
    public static let untitled = "Untitled"

    /// - Complexity: O(the text up to its first heading), at most the whole text.
    public static func of(_ text: String, kind: DocumentKind) -> String {
        var first: Substring?
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let trimmed = line.drop { $0 == " " || $0 == "\t" }
            guard !trimmed.allSatisfy(\.isWhitespace) else { continue }
            if first == nil { first = trimmed }
            guard kind == .markdown else { break }
            let hashes = trimmed.prefix { $0 == "#" }.count
            let rest = trimmed.dropFirst(hashes)
            if (1 ... 6).contains(hashes), rest.first == " " {
                // The heading's text, without the marks a heading may end with.
                let heading = clean(rest).reversed().drop { $0 == "#" || $0 == " " }.reversed()
                if !heading.isEmpty { return cut(String(heading)) }
            }
        }
        return first.map { cut(String(clean($0))) } ?? untitled
    }

    /// The name of the document's file when it leaves the store (the Trash, a file of the person's): what a file name cannot
    /// hold is replaced.
    public static func fileName(_ title: String, kind: DocumentKind) -> String {
        let safe = String(title.map { "/:".contains($0) ? "-" : $0 })
        return (safe.isEmpty ? untitled : safe) + "." + kind.fileExtension
    }

    private static func clean(_ line: Substring) -> Substring {
        var line = line.drop { $0.isWhitespace }
        while let last = line.last, last.isWhitespace { line.removeLast() }
        return line
    }

    private static func cut(_ title: String) -> String {
        title.count > limit ? String(title.prefix(limit)) : title
    }
}
