public import Foundation

/// What is saved to bring the content of a pane back: which kind it is and what that kind needs, as text (a terminal its directory, a note its text, a
/// page its address). The model does not know the kinds: one that the running build cannot make is kept as it is and written back, not dropped.
public struct PaneDescriptor: Sendable, Equatable, Codable {
    public static let terminalKind = "terminal"
    /// A document: Markdown, a diagram or text. Its state names a file or a stored document.
    public static let documentKind = "document"
    /// The picture of a document's tab.
    public static let documentSymbol = "doc.text"
    /// A document drawn as its page (rendered Markdown), not its source.
    public static let renderedDocumentSymbol = "richtext.page"

    /// The settings, as a tab. Its state names the topic shown.
    public static let settingsKind = "settings"
    /// The vault's page: the entry chosen in the Library's Passwords section (its scope's kind).
    public static let passwordsKind = "passwords"
    public static let settingsSymbol = "gearshape"
    public static let helpKind = "help"
    /// A web page (`SunsetWeb`). Its state's "url" is the address it opens.
    public static let webKind = "web"
    public static let helpSymbol = "questionmark.circle"

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

    /// A document that lives in Sunset's store, by its id.
    public static func document(stored id: UUID) -> PaneDescriptor {
        PaneDescriptor(kind: documentKind, state: ["document": id.uuidString])
    }

    /// A web page at `address`.
    public static func page(_ address: URL) -> PaneDescriptor {
        PaneDescriptor(kind: webKind, state: ["url": address.absoluteString])
    }

    /// The settings on the topic `topic` ("terminal.cursor").
    public static func settings(topic: String) -> PaneDescriptor {
        PaneDescriptor(kind: settingsKind, state: ["topic": topic, "title": "Settings"])
    }

    /// The vault's page. Which entry it shows is not kept: it opens on none.
    public static let passwords = PaneDescriptor(kind: passwordsKind, state: ["title": "Passwords"])

    /// Help, on the topic `topic`.
    public static func help(topic: String) -> PaneDescriptor {
        PaneDescriptor(kind: helpKind, state: ["topic": topic, "title": "Help"])
    }

    /// A document that is a file of the person's, by its path.
    public static func document(file path: String) -> PaneDescriptor {
        PaneDescriptor(kind: documentKind, state: ["file": path])
    }

    /// The file this brings back, as a document or in its viewer; nil for a document of the store and for any other kind.
    public var documentFile: String? {
        kind == Self.documentKind || kind == Self.fileViewKind ? state["file"] : nil
    }

    /// The stored document this brings back; nil for a file's document and for any other kind.
    public var storedDocument: UUID? {
        kind == Self.documentKind ? state["document"].flatMap(UUID.init(uuidString:)) : nil
    }

    /// What a tab that exists but is not loaded is found by, from what was saved of it: its page's title and address, its file's
    /// name and path, its directory. A loaded one is found by what its content says (`PaneContent.searchTerms`).
    public var searchTerms: [String] {
        var terms = [state["title"], state["url"], directory, documentFile.map { ($0 as NSString).lastPathComponent }]
        terms.append(documentFile)
        return terms.compactMap(\.self).filter { !$0.isEmpty }
    }

    /// The directory of a terminal; nil for any other kind.
    public var directory: String? {
        kind == Self.terminalKind ? state["directory"] : nil
    }
}
