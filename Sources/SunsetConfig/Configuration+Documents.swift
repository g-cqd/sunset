extension Configuration {
    /// When a file shown in a document pane is written by itself. By default two seconds after an edit and when it loses
    /// focus, as a document of Sunset's own store is kept. A document of the store is always kept, whatever these say.
    public struct Documents: Sendable, Equatable {
        /// A file is written this many seconds after its first unsaved edit; 0 is never.
        public var saveAfter = 2.0
        /// A file is written when its pane, or Sunset, stops being the one typed in.
        public var saveOnFocusLoss = true
        /// The source shows a heading at the page's size for its level: closer to what it becomes.
        public var largerHeadings = true
        /// Where a plain click on a document's link opens it.
        public var linksOpen = LinksOpen.tab

        public enum LinksOpen: String, Sendable, Equatable, CaseIterable {
            /// In a new tab, shown, as a browser.
            case tab
            /// Beside the document, in a split.
            case beside
        }

        public init() {}
    }
}
