extension Configuration.Tabs {
    /// What Command-T makes.
    public enum NewTab: String, Sendable, Equatable, CaseIterable {
        /// The focused tab's kind: a page makes a page, a document a document, anything else a terminal.
        case focused
        /// A terminal.
        case terminal
        /// A web page (private in a private page).
        case web
        /// A new document.
        case document
    }
}
