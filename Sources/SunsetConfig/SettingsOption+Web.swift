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
                "web.openLinksInSunset",
                "Open terminal links in Sunset",
                "link browser cmd-click",
                \.web.openLinksInSunset,
                label: "Cmd-click on a link in a terminal opens it in a page beside it"
            ),
            toggle(
                "web.showOpenedPages",
                "Pages a page opens",
                "popup pop-up new tab window target blank open image",
                \.web.showOpenedPages,
                label: "Show the pages a page opens, its pop-ups, pictures and films included"
            )
            .noted("Off, it waits in a tab after the page. Cmd-click and Open Link in New Tab always leave it there."),
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
