/// One option of Settings, declared once (the review of 2026-11-15): the file's key, what it is called, the words it is found
/// by and its control, in the list of its topic (`SettingsOption+*.swift`, `SettingsSection+All.swift`). The search entries,
/// the topics' pages and the controls all come from here.
public struct SettingsOption: Sendable, Identifiable {
    /// The file's key ("font.size"), or a name of its own for what is not one key of the file.
    public let id: String
    /// The keys of the file it sets: its own, but for the few that set several or none.
    public var keys: [String]
    /// The topic that shows it ("terminal.cursor"); set when its topic is made.
    public internal(set) var topic = ""
    public internal(set) var title: String
    /// Words it is found by, separated by spaces.
    public let words: String
    public let control: SettingsControl
    /// A sentence under the control.
    public var note: String?
    /// Shown a level down, under its topic's More, not first; found by search all the same.
    public var advanced = false
    /// What it holds is an address, a pattern, a file's name or code: its field is in monospace.
    public var isCode = false
    /// It can have a value of its own in the light scheme ("Separate for light and dark", design 0009).
    public var perScheme = false
    /// The option that holds its value in the light scheme, always apart (the tint's): shown in its row, not on its own.
    public var lightTwin: String?

    /// Shown only while this holds (a choice that acts only under another); nil, always.
    public var shownWhen: (@Sendable (Configuration) -> Bool)?

    /// Whether it is shown under `configuration`.
    public func isShown(in configuration: Configuration) -> Bool {
        shownWhen?(configuration) ?? true
    }

    /// The same, shown only while `condition` holds.
    public func shown(when condition: @escaping @Sendable (Configuration) -> Bool) -> Self {
        var copy = self
        copy.shownWhen = condition
        return copy
    }

    /// The heading it is shown under on its page, with the options next to it that have the same.
    public var group: String?

    /// Its control is a list of things the person added or answered (search engines, sites, profiles): its own block.
    /// Its control draws a section for each of its things (`SettingsControl.Custom.ownsSections`).
    public var ownsSections: Bool {
        guard case .custom(let custom) = control else { return false }
        return custom.ownsSections
    }

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
    /// The same under another title (its light and dark rows).
    public func titled(_ title: String) -> Self {
        var copy = self
        copy.title = title
        return copy
    }

    /// The same without its note (said once, under the first of two rows).
    public var unnoted: Self {
        var copy = self
        copy.note = nil
        return copy
    }

    /// The same, with `id` its value in the light scheme, shown beside its own.
    public func withLightTwin(_ id: String) -> Self {
        var copy = self
        copy.lightTwin = id
        return copy
    }

    /// The options shown in another's row as its light value.
    public static let lightTwins = Set(all.compactMap(\.lightTwin))

    /// The same, with a value of its own in light when asked.
    public var inBothSchemes: Self {
        var copy = self
        copy.perScheme = true
        return copy
    }

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

    /// A profile may set it otherwise than all profiles (search, privacy, network, downloads).
    public var isPerProfile = false

    /// The same, settable by each profile.
    public var perProfile: Self {
        var copy = self
        copy.isPerProfile = true
        return copy
    }

    /// Names its value had in files written before, read as the names they became ("transparent" was "fill").
    public var formerly: [String: String] = [:]

    /// The same, reading `names` (old to new) from older files.
    public func formerly(_ names: [String: String]) -> Self {
        var copy = self
        copy.formerly = names
        return copy
    }

    /// What it holds is a folder: its row has a picker beside the field.
    public var isFolder = false

    /// The same, a folder's: in monospace, with a picker.
    public func folder() -> Self {
        var copy = code()
        copy.isFolder = true
        return copy
    }

    /// A folder chosen in the picker, as the file writes it: `~` for the home folder.
    public static func written(folder: String, home: String) -> String {
        func trimmed(_ path: String) -> String {
            var path = path
            while path.count > 1, path.hasSuffix("/") { path.removeLast() }
            return path
        }
        let folder = trimmed(folder)
        let home = trimmed(home)
        if folder == home { return "~" }
        if folder.hasPrefix(home + "/") { return "~" + folder.dropFirst(home.count) }
        return folder
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
    public static func named(_ id: String) -> Self? {
        all.first { $0.id == id }
    }
}
