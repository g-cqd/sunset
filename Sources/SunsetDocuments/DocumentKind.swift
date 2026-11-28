/// What a document is: Markdown, a Mermaid diagram, a page (HTML, XHTML, SVG: drawn by WebKit), a table (CSV, TSV), data
/// (JSON, drawn as a tree), or plain text.
public enum DocumentKind: String, Sendable, Codable, CaseIterable {
    case markdown, mermaid, page, table, data, text

    /// The extension of its file when it leaves the store: the first its kind is read from, plain text's for text.
    public var fileExtension: String {
        self == .text ? "txt" : Self.byExtension.first { $0.value == self }.map(\.key) ?? "txt"
    }

    /// The kinds by the extensions they are read from, each kind's own first (`fileExtension`).
    static let byExtension: [(key: String, value: Self)] = [
        (Self.markdown, "md markdown mdown mkd mkdn mdwn"), (.mermaid, "mmd mermaid"), (.page, "html htm xhtml svg"),
        (.table, "csv tsv"), (.data, "json geojson")
    ]
    .flatMap { kind, names in names.split(separator: " ").map { (key: String($0), value: kind) } }
}
