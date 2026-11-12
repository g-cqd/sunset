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

        /// Cmd-click on a link in a terminal opens it in a page beside the terminal; off: in the default browser.
        public var openLinksInSunset = true
        /// The page's inspector (Inspect Element, and Safari's Develop menu) can be opened.
        public var developer = true
        public var tabIcon = TabIcon.initial
        public var address = AddressPlace.sidebar
        public var windowBar = BarEdge.top
        public init() {}
    }
}
