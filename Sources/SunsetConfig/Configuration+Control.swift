extension Configuration {
    /// `control.*`: the app asked from outside, over its control socket and the `sunset` tool (ADR-0129). Both off.
    public struct Control: Sendable, Equatable {
        /// The socket answers: the panes listed and read, the menus' commands run, a screen waited on.
        public var enabled = false
        /// It may also type into terminals.
        public var typing = false

        public init() {}
    }
}
