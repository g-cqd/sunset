extension Configuration {
    /// The web pane.
    public struct Web: Sendable, Equatable {
        /// What a page's tab shows when it has no icon of its own: the first letter of its title in a square, or a globe.
        public enum TabIcon: String, Sendable, Equatable, CaseIterable {
            case favicon, initial, globe
        }

        /// Where the address of the focused page is typed (web step b): a compact field at the top of the sidebar, a bar of the window that shows
        /// when the pointer reaches its edge, or a row at the top of every page.
        public enum AddressPlace: String, Sendable, Equatable, CaseIterable {
            case sidebar, window, pane
        }

        public enum SplitBar: String, Sendable, Equatable, CaseIterable {
            case margin, pane
        }

        /// Which pop-ups open in a pop-up window: those the page sizes, every one a script opens, or none (tabs).
        public enum PopupWindows: String, Sendable, Equatable, CaseIterable {
            case sized, scripted, never
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

        /// The browser a site with no rule of its own is shown: Safari is Sunset as it is; the others change what the
        /// User-Agent says, and nothing else of the engine.
        public enum Agent: String, Sendable, Equatable, CaseIterable {
            case safari, chrome, edge, firefox
        }

        /// How long the history keeps a page (web step e). What WebKit keeps between runs: app-wide; a profile may set
        /// otherwise.
        public struct Keep: Sendable, Equatable {
            /// The caches, the traces: kept, or cleared when Sunset quits.
            public enum Choice: String, Sendable, Equatable, CaseIterable {
                case keep, clearOnQuit
            }

            /// A site's data: kept, kept for the sites chosen or signed in to only, or cleared when Sunset quits.
            public enum SiteData: String, Sendable, Equatable, CaseIterable {
                case keep, keepChosen, clearOnQuit
            }

            public var cache: Choice
            public var traces: Choice
            public var siteData: SiteData

            public init(cache: Choice = .keep, traces: Choice = .keep, siteData: SiteData = .keep) {
                self.cache = cache
                self.traces = traces
                self.siteData = siteData
            }

            /// The same, with a profile's own choices (their names; nil, or one not known: this one's).
            public func overriding(cache: String?, traces: String?, siteData: String?) -> Self {
                Self(
                    cache: cache.flatMap(Choice.init(rawValue:)) ?? self.cache,
                    traces: traces.flatMap(Choice.init(rawValue:)) ?? self.traces,
                    siteData: siteData.flatMap(SiteData.init(rawValue:)) ?? self.siteData
                )
            }
        }

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
        /// A page's request to notify asks without a click too (Chrome's way); off, Safari's.
        public var notificationsWithoutClick = false
        /// A page's notifications through its service worker's registration are posted too.
        public var workerNotifications = true
        /// The site's icon, its initial in a square while it has none (owner, 2026-11-13).
        public var tabIcon = TabIcon.favicon
        public var address = AddressPlace.sidebar
        public var windowBar = BarEdge.top
        /// In a split, where the window bar goes while it is out: in a margin that opens above the panes (they keep their size,
        /// only less of them shows), or over the focused pane (owner, 2026-11-13).
        public var splitBar = SplitBar.margin
        /// A page a page opens (a link with a target, a pop-up after a click, Open Image in New Window) is shown, as Safari
        /// does; off, it waits in a tab after its opener.
        public var showOpenedPages = true
        /// Which pop-ups open in a window of their own with no sidebar, a page that is no tab until moved to a Space.
        public var popupWindows = PopupWindows.sized
        /// A link from another app (Sunset the Mac's browser) opens in a peek window: back, forward, an address field, moved to a
        /// Space by the person. Off, a tab of the window in front.
        public var peekLinks = true
        /// Pages animate and redraw at the screen's rate (120 fps on a ProMotion screen), not near 60 (owner, 2026-11-13).
        public var fullFrameRate = true
        /// The name of the engine words are searched with (a built-in one or one of `engines`).
        public var engine = "Google"
        /// Engines added to the built-in ones (Google, DuckDuckGo, Bing, Ecosia, Kagi); one with a built-in name replaces it.
        public var engines: [Engine] = []
        /// What is typed is sent to the engine for suggestions (never an address of this machine or the local network).
        public var suggestions = true
        /// Retired: `web.httpsUpgrade` decides for a typed address too. Still read, so that a file that sets it reads
        /// cleanly; nothing uses it.
        public var httpFallback = false
        public var httpsUpgrade = HTTPSUpgrade.fallback
        public var hardening = Hardening.off
        public var globalPrivacyControl = PrivacyControl.privateWindows
        public var zoomScope = ZoomScope.site
        public var agent = Agent.safari
        /// What a page's scripts read to tell a browser is set to what `agent` (or the site's rule) names: the second
        /// rung. Off: the User-Agent only.
        public var agentScripts = true
        /// Zoom makes only the text bigger, not the images (WebKit's private text zoom; nothing where it is missing).
        public var textOnlyZoom = false
        public var historyKeep = HistoryKeep.year
        /// What goes when Sunset quits: the history, the website data (cookies, caches, storage).
        public var clearHistoryOnQuit = false
        public var keep = Keep(siteData: .keepChosen)
        /// A page may be offered other profiles' tabs to share.
        public var shareOtherProfiles = false
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
        /// A page not on screen is unloaded after this many hours (0: never by the delay), and when memory runs short,
        /// the longest idle first.
        public var unloadAfter = 12.0
        public var unloadUnderPressure = true
        /// Ads and trackers are blocked with these lists, which Sunset fetches itself: https only.
        public var blocking = true
        public var blockingLists = Self.defaultBlockingLists
        /// The proxy every page goes through: `http://host:port` or `socks5://host:port`; empty for none.
        public var proxy = ""
        public static let defaultBlockingLists = [
            "https://easylist.to/easylist/easylist.txt", "https://easylist.to/easylist/easyprivacy.txt"
        ]
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
