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
    /// Shown a level down, under its topic's More, not first (roadmap 0047 G); found by search all the same.
    public var advanced = false
    /// What it holds is an address, a pattern, a file's name or code: its field is in monospace (the owner's note n26).
    public var isCode = false

    /// Shown only while this holds (the owner's note n29: a choice that acts only under another); nil, always.
    public var shownWhen: (@Sendable (Configuration) -> Bool)?

    /// Whether it is shown under `configuration`.
    public func isShown(in configuration: Configuration) -> Bool { shownWhen?(configuration) ?? true }

    /// The same, shown only while `condition` holds.
    public func shown(when condition: @escaping @Sendable (Configuration) -> Bool) -> Self {
        var copy = self
        copy.shownWhen = condition
        return copy
    }

    /// The heading it is shown under on its page, with the options next to it that have the same (the owner's note n13).
    public var group: String?

    /// Its control is a list of things the person added or answered (search engines, sites, profiles): its own block.
    public var isList: Bool {
        guard case .custom(let custom) = control else { return false }
        return custom.isList
    }

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

    /// The same, a level down.
    public var further: Self {
        var copy = self
        copy.advanced = true
        return copy
    }

    /// The same, its field in monospace.
    public func code() -> Self {
        var copy = self
        copy.isCode = true
        return copy
    }

    /// The same, under the heading `title` on its page.
    public func grouped(_ title: String) -> Self {
        var copy = self
        copy.group = title
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
