extension Configuration {
    /// The scopes of the app, each of which can be removed whole ("a toggle that remove all the web navigation scope, one
    /// that removes completely the terminal from the app features, and one that removes document visualization and
    /// handling and rendering except downloads"). All on by default; at least one stays on.
    public struct Features: Sendable, Equatable {
        public var terminal: Bool
        public var web: Bool
        public var documents: Bool
        /// Sunset's own password management: off until the person turns it on; while off, no vault, no fill script, no
        /// menu. Not a kind of tab, so not among `count`.
        public var credentials = false

        public init(terminal: Bool = true, web: Bool = true, documents: Bool = true) {
            self.terminal = terminal
            self.web = web
            self.documents = documents
        }

        /// How many are on.
        public var count: Int {
            [terminal, web, documents].count { $0 }
        }
    }
}
