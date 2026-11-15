/// One option of Settings, declared once (the review of 2026-11-15; task t268): the file's key, what it is called, the words
/// it is found by and its control, in the list of its topic (`SettingsOption+*.swift`, `SettingsSection+All.swift`). The search
/// entries, the topics' pages and the controls all come from here.
public struct SettingsOption: Sendable, Identifiable {
    /// The file's key ("font.size"), or a name of its own for what is not one key of the file.
    public let id: String
    /// The keys of the file it sets: its own, but for the few that set several or none.
    public var keys: [String]
    /// The topic that shows it ("terminal.cursor"); set when its topic is made.
    public internal(set) var topic = ""
    public let title: String
    /// Words it is found by, separated by spaces.
    public let words: String
    public let control: SettingsControl
    /// A sentence under the control.
    public var note: String?

    public init(_ id: String, _ title: String, _ words: String, _ control: SettingsControl) {
        self.id = id
        keys = [id]
        self.title = title
        self.words = words
        self.control = control
    }

    /// What the search looks through.
    public var entry: SettingsEntry {
        SettingsEntry(id: id, pane: topic, title: title, keywords: words.split(separator: " ").map(String.init))
    }

    /// The same with a sentence under its control.
    public func noted(_ note: String) -> Self {
        var copy = self
        copy.note = note
        return copy
    }

    /// The same, setting `keys` of the file (several, or none).
    public func setting(_ keys: [String]) -> Self {
        var copy = self
        copy.keys = keys
        return copy
    }

    /// Every option, section after section and topic after topic, in the order each page shows them.
    public static let all: [Self] = SettingsSection.all.flatMap(\.topics).flatMap(\.options)

    /// The option named `id`.
    public static func named(_ id: String) -> Self? { all.first { $0.id == id } }
}
