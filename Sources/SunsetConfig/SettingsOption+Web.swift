/// The options of Web (R1): the address, search, pages.
extension SettingsOption {
    /// The address and the bars.
    static let addressBars: [Self] =
        [
            choice(
                "web.address",
                "Address field",
                "address url bar",
                \.web.address,
                [
                    (.sidebar, "At the top of the sidebar"),
                    (.window, "In a bar at the window's edge"),
                    (.pane, "At the top of every page")
                ]
            ),
            choice(
                "web.windowBar",
                "Window bar position",
                "address top bottom",
                \.web.windowBar,
                [(.top, "Top"), (.bottom, "Bottom")]
            ),
            choice(
                "web.splitBar",
                "Window bar in a split",
                "address split margin pane",
                \.web.splitBar,
                [(.margin, "Above the panes"), (.pane, "Over the focused pane")]
            )
        ]

    /// Search.
    static let search: [Self] =
        [
            custom("web.engine", "Search engine", "search google duckduckgo kagi", .searchEngine)
                .perProfile,
            custom("web.engines", "Added search engines", "engine keyword custom", .engines)
                .noted(
                    "Typing an engine's keyword, a space and words searches it. In its addresses, `%s` stands for the "
                        + "words; the suggestion address answers in the OpenSearch JSON format."
                ),
            toggle(
                "web.suggestions",
                "Search suggestions",
                "suggest autocomplete",
                \.web.suggestions,
                label: "Ask the engine for suggestions while typing"
            )
            .perProfile
            .grouped("Suggestions"),
            toggle(
                "web.privateSuggestions",
                "Suggestions in private pages",
                "private incognito suggest",
                \.web.privateSuggestions,
                label: "Ask the engine for suggestions in private pages"
            )
            .perProfile
            .grouped("Suggestions")
        ]

    /// Pages.
    static let pages: [Self] =
        [
            // Not a key of the file: the system's choice, shown and asked for (the owner's note n18).
            custom(
                "web.defaultBrowser",
                "Default browser",
                "default browser links open system macos safari",
                .defaultBrowser
            )
            .setting([]),
            toggle(
                "web.peekLinks",
                "Links from other apps",
                "peek link other app default browser window open",
                \.web.peekLinks,
                label: "Open links from other apps in a peek window"
            )
            .noted("A peek has back, forward and an address; Open in moves its page to a Space as a tab. Off, a tab."),
            toggle(
                "web.openLinksInSunset",
                "Open terminal links in Sunset",
                "link browser cmd-click",
                \.web.openLinksInSunset,
                label: "⌘-click on a link in a terminal opens it in a page beside it"
            ),
            toggle(
                "web.showOpenedPages",
                "Pages a page opens",
                "popup pop-up new tab window target blank open image",
                \.web.showOpenedPages,
                label: "Show the pages a page opens, its pop-ups, pictures and videos included"
            )
            .noted("Off, it waits in a tab after the page. ⌘-click and Open Link in New Tab always leave it there.")
            .grouped("New pages"),
            choice(
                "web.popupWindows",
                "Pop-up windows",
                "popup pop-up window sign in login sized",
                \.web.popupWindows,
                [(.sized, "Pop-ups a page sizes"), (.scripted, "Every pop-up a script opens"), (.never, "None")]
            )
            .noted(
                "A pop-up window has no sidebar; Open in moves its page to a Space as a tab. A link to a new tab stays a tab."
            )
            .grouped("New pages"),
            toggle(
                "web.httpFallback",
                "Fall back to HTTP",
                "http https insecure",
                \.web.httpFallback,
                label: "Try HTTP when HTTPS fails for a host typed without a scheme"
            ),
            choice(
                "web.zoomScope",
                "Page zoom",
                "zoom site scale",
                \.web.zoomScope,
                [
                    (.site, "Per site"), (.session, "Per site until Sunset quits"),
                    (.page, "Per page")
                ]
            )
            .noted("Per page, the zoom is saved with the page's tab."),
            custom("web.textOnlyZoom", "Zoom text only", "zoom text font", .textOnlyZoom)
        ]
}
