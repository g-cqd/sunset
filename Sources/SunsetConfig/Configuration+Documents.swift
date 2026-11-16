extension Configuration {
    /// When a file shown in a document pane is written by itself (R6). By default two seconds after an edit and when it
    /// loses focus, as a document of Sunset's own store is kept (the owner, 2026-11-16, ADR-0041, which supersedes the
    /// "neither by default" of ADR-0038). A document of the store is always kept, whatever these say.
    public struct Documents: Sendable, Equatable {
        /// A file is written this many seconds after its first unsaved edit; 0 is never.
        public var saveAfter = 2.0
        /// A file is written when its pane, or Sunset, stops being the one typed in.
        public var saveOnFocusLoss = true

        public init() {}
    }
}
