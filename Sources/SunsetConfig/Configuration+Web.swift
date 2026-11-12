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

        /// What a page's zoom applies to (web step d): every page of its site, remembered across launches; the site until the app quits; the page
        /// alone, saved with it.
        public enum ZoomScope: String, Sendable, Equatable, CaseIterable {
            case site, session, page
        }

        /// How long the history keeps a page (web step e).
        public enum HistoryKeep: String, Sendable, Equatable, CaseIterable {
            case day, week, twoWeeks, month, year, forever

            /// In seconds; nil for ever.
            public var seconds: Double? {
                switch self {
                    case .day: 86_400
                    case .week: 7 * 86_400
                    case .twoWeeks: 14 * 86_400
                    case .month: 31 * 86_400
                    case .year: 365 * 86_400
                    case .forever: nil
                }
            }
        }

        /// How long the list of downloads keeps a finished one (web step f).
        public enum DownloadsKeep: String, Sendable, Equatable, CaseIterable {
            case byHand, day, week, month, untilQuit, whenFinished
        }

        /// What a site gets before it was answered (web step g).
        public enum PermissionDefault: String, Sendable, Equatable, CaseIterable {
            case ask, allow, deny
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
        public var zoomScope = ZoomScope.site
        /// Zoom makes only the text bigger, not the images (WebKit's private text zoom; nothing where it is missing).
        public var textOnlyZoom = false
        public var historyKeep = HistoryKeep.year
        /// What goes when Sunset quits: the history, the website data (cookies, caches, storage).
        public var clearHistoryOnQuit = false
        public var clearWebsiteDataOnQuit = false
        /// Where files are downloaded; empty: ~/Downloads.
        public var downloadFolder = ""
        public var askWhereToSave = false
        /// Pictures, PDF, text, sound and film open once downloaded.
        public var openSafeDownloads = false
        public var notifyDownloads = true
        /// Apps, installers and scripts are downloaded only after an approval.
        public var approveRiskyDownloads = true
        public var keepDownloads = DownloadsKeep.byHand
        /// Suggestions while typing in a private page (web step h).
        public var privateSuggestions = false
        /// The pages of a new private window share one store (its selector changes it for the window).
        public var privateWindowShares = true
        /// By permission name (camera, microphone, screen, location, notifications, popups, autoplay): what a site not yet answered gets.
        public var permissions: [String: PermissionDefault] = Self.permissionDefaults
        public static let permissionNames = [
            "camera", "microphone", "screen", "location", "notifications", "popups", "autoplay"
        ]
        public static let permissionDefaults: [String: PermissionDefault] = [
            "camera": .ask, "microphone": .ask, "screen": .ask, "location": .ask, "notifications": .ask,
            "popups": .deny,
            "autoplay": .deny
        ]
        public init() {}
    }
}
