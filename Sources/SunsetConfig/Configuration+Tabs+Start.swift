extension Configuration.Tabs {
    /// What opens when Sunset, or a window on an empty Space, starts with no tab (the owner's note n74).
    public enum Start: String, Sendable, Equatable, CaseIterable {
        /// Nothing: the window is empty.
        case nothing
        /// A terminal.
        case terminal
        /// A new web page, its address asked for.
        case web
        /// A page at `startAddress`.
        case address
        /// A new document.
        case newDocument
        /// The document file at `startFile`.
        case file
    }
}
