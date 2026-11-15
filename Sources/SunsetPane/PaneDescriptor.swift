/// What is saved to bring the content of a pane back: which kind it is and what that kind needs, as text (a terminal its directory, a note its text, a
/// page its address). The model does not know the kinds: one that the running build cannot make is kept as it is and written back, not dropped.
public struct PaneDescriptor: Sendable, Equatable, Codable {
    public static let terminalKind = "terminal"
    /// A document: Markdown, a diagram or text (roadmap 0023). Its state names a file or a stored document.
    public static let documentKind = "document"
    /// The picture of a document's tab.
    public static let documentSymbol = "doc.text"

    public var kind: String
    public var state: [String: String]

    public init(kind: String, state: [String: String] = [:]) {
        self.kind = kind
        self.state = state
    }

    /// A terminal, to be started in `directory` (programs cannot be saved: a restored pane is a new shell there).
    public static func terminal(directory: String?) -> PaneDescriptor {
        PaneDescriptor(kind: terminalKind, state: directory.map { ["directory": $0] } ?? [:])
    }

    /// The directory of a terminal; nil for any other kind.
    public var directory: String? { kind == Self.terminalKind ? state["directory"] : nil }
}
