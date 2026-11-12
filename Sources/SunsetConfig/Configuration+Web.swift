extension Configuration {
    /// The web pane (R1).
    public struct Web: Sendable, Equatable {
        /// What a page's tab shows when it has no icon of its own: the first letter of its title in a square, or a globe.
        public enum TabIcon: String, Sendable, Equatable, CaseIterable {
            case initial, globe
        }

        /// Where the address of the focused page is typed (web step b): a compact field at the top of the sidebar, a bar of the window that shows
        /// when the pointer reaches its edge, or a row at the top of every page.
        public enum AddressPlace: String, Sendable, Equatable, CaseIterable {
            case sidebar, window, pane
        }

        /// The edge of the window bar (also used for the sidebar's field while the sidebar is not shown).
        public enum BarEdge: String, Sendable, Equatable, CaseIterable {
            case top, bottom
        }

        /// A search engine the person added (`web.engines`): `%s` in the addresses stands for the words; the suggestion address answers in the
        /// OpenSearch JSON format.
        public struct Engine: Sendable, Equatable {
            public var name: String
            public var keyword: String
            public var search: String
            public var suggest: String?
            public init(name: String, keyword: String, search: String, suggest: String? = nil) {
                self.name = name
                self.keyword = keyword
                self.search = search
                self.suggest = suggest
            }
        }

        /// Cmd-click on a link in a terminal opens it in a page beside the terminal; off: in the default browser.
        public var openLinksInSunset = true
        /// The page's inspector (Inspect Element, and Safari's Develop menu) can be opened.
        public var developer = true
        public var tabIcon = TabIcon.initial
        public var address = AddressPlace.sidebar
        public var windowBar = BarEdge.top
        /// The name of the engine words are searched with (a built-in one or one of `engines`).
        public var engine = "Google"
        /// Engines added to the built-in ones (Google, DuckDuckGo, Bing, Ecosia, Kagi); one with a built-in name replaces it.
        public var engines: [Engine] = []
        /// What is typed is sent to the engine for suggestions (never an address of this machine or the local network).
        public var suggestions = true
        /// A host typed without a scheme that fails over https is tried over http (marked Not Secure).
        public var httpFallback = false
        public init() {}
    }
}
