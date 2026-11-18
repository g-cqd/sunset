extension HelpCatalog {
    /// What a website may do, and what Sunset keeps of it (roadmap 0041 D; white paper §9: what an untrusted page asks for
    /// has a policy).
    static let web: [HelpTopic: HelpEntry] = [
        .sitePermissions: HelpEntry(
            title: "What sites may do",
            summary: "A site asks before it uses the camera, microphone, screen, location or notifications.",
            text: [
                "Allow keeps the answer for the site; Allow Once lasts while the page is open; Don't Allow keeps the refusal.",
                "Pop-up windows and sound that plays on its own are blocked unless you allow them. Settings > Web > "
                    + "Websites lists every site's answers and the defaults."
            ],
            expert: [
                "The camera, the microphone and the location also need macOS to allow Sunset: a site you allowed shows "
                    + "a button under the sidebar's field when macOS has not."
            ],
            related: [.webNotifications, .popUps, .pageDialogs]
        ),
        .webNotifications: HelpEntry(
            title: "Notifications from sites",
            summary:
                "A site you allow posts to Notification Center; it can ask only after you click or type on its page.",
            text: [
                "A site that asks while it loads, before you did anything on it, is not asked about; allow it in its settings "
                    + "if you want it.",
                "A site shows one notification a second at most; clicking one shows its tab and tells the page."
            ],
            related: [.sitePermissions]
        ),
        .popUps: HelpEntry(
            title: "Pop-up windows",
            summary: "Pop-up windows a page opens on its own are blocked, unless you allow them for the site.",
            text: [
                "What a click opens is not a pop-up: a link to a new window opens as a tab, and a page that asks for a "
                    + "window of its own size gets a small window."
            ],
            related: [.sitePermissions]
        ),
        .pageDialogs: HelpEntry(
            title: "Dialogs from pages",
            summary: "From a page's second dialog on, you can silence it until you leave the page.",
            text: [
                "A page's alerts, confirmations and questions show in its pane. A silenced page's dialogs are answered "
                    + "without being shown."
            ],
            related: [.sitePermissions]
        ),
        .downloads: HelpEntry(
            title: "Downloads",
            summary:
                "Apps, installers and scripts are downloaded only after you approve them; other files go to your folder.",
            text: [
                "Settings > Web > Downloads sets the folder, whether to ask where to save each file, and how long the "
                    + "list keeps finished downloads.",
                "Safe files (pictures, PDF, text, sound and film) can open once downloaded; an app, an installer or a "
                    + "script never does."
            ],
            related: [.sitePermissions]
        ),
        .profiles: HelpEntry(
            title: "Profiles",
            summary: "A profile is a web identity: its own cookies, logins, storage, Pinned grid and Favorites.",
            text: [
                "A Space belongs to one profile, chosen in the Space's editor. A tab dragged to a window of another profile "
                    + "loads its pages again as that profile's.",
                "History, what sites may do and how sites see Sunset are shared by all profiles for now."
            ],
            related: [.privateBrowsing, .dragAndDrop]
        ),
        .privateBrowsing: HelpEntry(
            title: "Private browsing",
            summary: "A private page keeps no history and no website data once it is closed.",
            text: [
                "Open one from +'s menu (New Private Tab) or in a private window. A private tab of a normal window shares "
                    + "nothing with other pages.",
                "Settings > Privacy and security sets whether the pages of one private window share their data."
            ],
            related: [.profiles]
        ),
        .plainHTTP: HelpEntry(
            title: "Pages over plain http",
            summary: "A page over plain http is marked: what it sends and receives can be read and changed on the way.",
            text: [
                "An address typed without a scheme is tried over https first; Settings > Web says whether to fall back to "
                    + "http when https fails."
            ],
            related: [.sitePermissions]
        ),
        .browserIdentity: HelpEntry(
            title: "Appearing as another browser",
            summary:
                "Sunset can tell sites it is Chrome, Edge or Firefox, for every site or for one, when a site needs it.",
            text: [
                "Settings > Web > Websites sets the browser every site is shown; a site's panel in the address field gives "
                    + "that site its own. The page loads again to take it.",
                "What changes is what Sunset says it is: the User-Agent of each request, and, unless \"Tell a page's "
                    + "scripts the same\" is off, what the page's scripts read (the vendor, the client hints)."
            ],
            expert: [
                "The engine is still WebKit: features Chrome has and WebKit has not stay missing, client-hint headers are "
                    + "not sent, and a site that looks further can tell. If a site breaks, show it Safari again."
            ],
            related: [.sitePermissions, .profiles]
        )
    ]
}
