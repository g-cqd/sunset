extension Configuration {
    /// `sidebar.*`.
    public struct Sidebar: Sendable, Equatable {
        /// The order of the documents in the sidebar's lists.
        public enum DocumentSort: String, Sendable, Equatable, CaseIterable {
            case changed, made, name, kind
        }

        public var enabled = true
        /// Width in points.
        public var width = 229.0
        /// Space of the window's colour between the terminal and the window's edge and the sidebar while the sidebar is shown, in
        /// points. The terminal is a card then, its corners concentric with the window's (16 pt): with 6 its radius is 10.
        public var padding = 4.0
        /// The sidebar is hidden, and floats over the terminal as a glass panel (holding the traffic lights) while the pointer is at
        /// the leading edge; false: it stays beside the terminal.
        public var autoHide = false
        /// The edge of the window the sidebar is on.
        public var side = Side.right
        /// The Library: a glyph at the sidebar's foot that widens it by a rail of sections.
        public var library = true
        public var documentSort = DocumentSort.changed
        /// The lines between the Pinned grid, the Favorites and the tabs; off, their space stays.
        public var separators = true
        /// How the Spaces show at the sidebar's foot (`SpacesStyle`).
        public var spaces = SpacesStyle.auto
        /// A card when a row is pointed at (`previews`), and of which kinds.
        public var previews = true
        public var previewPages = true
        public var previewTerminals = true
        public var previewDocuments = true
        public var previewFolders = true

        public init() {}
    }
}
