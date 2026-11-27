/// One request to the app over its control socket (`ControlServer`): a line of JSON.
public struct ControlRequest: Codable, Sendable, Equatable {
    public enum Verb: String, Codable, Sendable, CaseIterable {
        /// The panes of every window: id, kind, title, which is shown.
        case list
        /// The text of a pane: a terminal's screen (and scrollback lines before it), a page's address and title.
        case read
        /// Text typed into a terminal, as keys are: "\r" runs a line.
        case type
        /// A command of the menus, by its name (`commands` lists them).
        case run
        /// The commands that can be run.
        case commands
        /// Until a terminal's screen shows a text, or the time is up.
        case wait
    }

    public var verb: Verb
    /// A pane's id from `list`, or "shown": the pane shown in the window in front.
    public var pane: String?
    /// What `type` types, what `wait` waits for, the command `run` runs.
    public var text: String?
    /// For `read`: how many lines of scrollback before the screen.
    public var lines: Int?
    /// For `wait`: seconds.
    public var timeout: Double?

    public init(_ verb: Verb, pane: String? = nil, text: String? = nil, lines: Int? = nil, timeout: Double? = nil) {
        self.verb = verb
        self.pane = pane
        self.text = text
        self.lines = lines
        self.timeout = timeout
    }
}
