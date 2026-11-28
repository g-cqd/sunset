/// What a scope is: the kind of pane it makes, and how it is named and shown where it is switched on and off (Settings ▸
/// General and the welcome). One table, so that a scope added is added whole.
extension Scopes.Scope {
    /// Per scope, in `allCases`' order: kind, title, name, symbol, what it is. A kind is `PaneDescriptor`'s
    /// (`ScopesTests` checks them).
    private static let table = """
        terminal|Terminals|terminals|terminal|Shells in tabs and panes, with sessions kept.
        web|Web|the web|globe|Pages, Spaces and extensions, with ads and trackers blocked.
        document|Documents|documents|doc.text|Markdown, web pages and text files read and edited; PDFs, pictures and films.
        passwords|Passwords|passwords|key|Passwords, cards and notes in a vault of your own, sealed on this Mac.
        """
        .split(separator: "\n")
        .map { $0.split(separator: "|").map(String.init) }

    private func word(_ column: Int) -> String {
        Self.table[Self.allCases.firstIndex(of: self) ?? 0][column]
    }

    /// The kind of pane it is (`PaneDescriptor.kind`); the vault's is the kind of no pane.
    public var kind: String {
        word(0)
    }

    public var title: String {
        word(1)
    }

    /// In a sentence: "Turn off the web?"
    public var name: String {
        word(2)
    }

    /// An SF Symbol.
    public var symbol: String {
        word(3)
    }

    /// What it is, in a line.
    public var detail: String {
        word(4)
    }
}
