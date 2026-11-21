extension Configuration.Tabs {
    public enum Mode: String, Sendable, Equatable, CaseIterable {
        /// One terminal per window.
        case none
        /// The system's tabs (and the sidebar, when on, lists the same tabs).
        case native
        /// A tab bar in the terminal window itself; native tabs and the sidebar are off.
        case `internal`
    }
}
