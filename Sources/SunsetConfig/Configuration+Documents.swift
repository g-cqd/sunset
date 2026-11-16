extension Configuration {
    /// When a file shown in a document pane is written by itself (R6). Neither by default: a file changes when its owner
    /// says so. A document of Sunset's own store is always kept, whatever these say.
    public struct Documents: Sendable, Equatable {
        /// A file is written this many seconds after its first unsaved edit; 0 is never.
        public var saveAfter = 0.0
        /// A file is written when its pane, or Sunset, stops being the one typed in.
        public var saveOnFocusLoss = false

        public init() {}
    }
}
