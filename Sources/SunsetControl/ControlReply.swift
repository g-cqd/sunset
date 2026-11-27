/// The app's answer to a `ControlRequest`: a line of JSON.
public struct ControlReply: Codable, Sendable, Equatable {
    /// A pane, as `list` tells it.
    public struct Pane: Codable, Sendable, Equatable {
        public var id: String
        /// "terminal", "page", "document" or another kind's name.
        public var kind: String
        public var title: String
        public var detail: String?
        /// The window it is in, counting from 0 for the one in front.
        public var window: Int
        /// Shown in its window.
        public var shown: Bool

        public init(id: String, kind: String, title: String, detail: String?, window: Int, shown: Bool) {
            self.id = id
            self.kind = kind
            self.title = title
            self.detail = detail
            self.window = window
            self.shown = shown
        }
    }

    public var ok: Bool
    public var error: String?
    public var text: String?
    public var panes: [Pane]?
    public var commands: [String]?

    public init(text: String? = nil, panes: [Pane]? = nil, commands: [String]? = nil) {
        ok = true
        self.text = text
        self.panes = panes
        self.commands = commands
    }

    public static func failure(_ message: String) -> Self {
        var reply = Self()
        reply.ok = false
        reply.error = message
        return reply
    }
}
