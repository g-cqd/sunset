public import Foundation

/// What is saved to bring the content of a pane back: which kind it is and what that kind needs, as text (a terminal its directory, a note its text, a
/// page its address). The model does not know the kinds: one that the running build cannot make is kept as it is and written back, not dropped.
public struct PaneDescriptor: Sendable, Equatable, Codable {
    public static let terminalKind = "terminal"
    /// A document: Markdown, a diagram or text (roadmap 0023). Its state names a file or a stored document.
    public static let documentKind = "document"
    /// The picture of a document's tab.
    public static let documentSymbol = "doc.text"
    /// A document drawn as its page (rendered Markdown), not its source (note n3).
    public static let renderedDocumentSymbol = "richtext.page"

    /// The settings, as a tab (roadmap 0032). Its state names the topic shown.
    public static let settingsKind = "settings"
    public static let settingsSymbol = "gearshape"
    public static let helpKind = "help"
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

    /// The settings on the topic `topic` ("terminal.cursor").
    public static func settings(topic: String) -> PaneDescriptor {
        PaneDescriptor(kind: settingsKind, state: ["topic": topic, "title": "Settings"])
    }

    /// Help, on the topic `topic` (roadmap 0041 E).
    public static func help(topic: String) -> PaneDescriptor {
        PaneDescriptor(kind: helpKind, state: ["topic": topic, "title": "Help"])
    }

    /// A document that is a file of the person's, by its path.
    public static func document(file path: String) -> PaneDescriptor {
        PaneDescriptor(kind: documentKind, state: ["file": path])
    }

    /// The file this brings back; nil for a document of the store and for any other kind.
    public var documentFile: String? { kind == Self.documentKind ? state["file"] : nil }

    /// The stored document this brings back; nil for a file's document and for any other kind.
    public var storedDocument: UUID? {
        kind == Self.documentKind ? state["document"].flatMap(UUID.init(uuidString:)) : nil
    }

    /// The directory of a terminal; nil for any other kind.
    public var directory: String? { kind == Self.terminalKind ? state["directory"] : nil }
}
