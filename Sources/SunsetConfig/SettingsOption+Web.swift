/// The options of Web (R1): the address, search, pages.
extension SettingsOption {
    /// The address and the bars.
    static let addressBars: [Self] =
        [
            choice(
                "web.address",
                "Where the address is",
                "address url bar",
                \.web.address,
                [
                    (.sidebar, "A field at the top of the sidebar"),
                    (.window, "A bar of the window, shown at its edge"),
                    (.pane, "A row at the top of every page")
                ],
                label: "The address is typed in"
            ),
            choice(
                "web.windowBar",
                "Window bar edge",
                "address top bottom",
                \.web.windowBar,
                [(.top, "Top"), (.bottom, "Bottom")],
                label: "The window bar is at the"
            ),
            choice(
                "web.splitBar",
                "Window bar in a split",
                "address split margin pane",
                \.web.splitBar,
                [(.margin, "Above the panes"), (.pane, "Over the focused pane")],
                label: "In a split, the window bar goes"
            )
        ]

    /// Search.
    static let search: [Self] =
        [
            custom("web.engine", "Search engine", "search google duckduckgo kagi", .searchEngine),
            custom("web.engines", "Added search engines", "engine keyword custom", .engines),
            toggle(
                "web.suggestions",
                "Search suggestions",
                "suggest autocomplete",
                \.web.suggestions,
                label: "Ask the engine for suggestions while typing"
            ),
            toggle(
                "web.privateSuggestions",
                "Suggestions in private pages",
                "private incognito suggest",
                \.web.privateSuggestions,
                label: "Ask the engine for suggestions in private pages"
            )
        ]

    /// Pages.
    static let pages: [Self] =
        [
            toggle(
                "web.openLinksInSunset",
                "Open terminal links in Sunset",
                "link browser cmd-click",
                \.web.openLinksInSunset,
                label: "Cmd-click on a link in a terminal opens it in a page beside it"
            ),
            toggle(
                "web.httpFallback",
                "Fall back to http",
                "http https insecure",
                \.web.httpFallback,
                label: "Try http when https fails for a host typed without a scheme"
            ),
            choice(
                "web.zoomScope",
                "Page zoom applies to",
                "zoom site scale",
                \.web.zoomScope,
                [
                    (.site, "Its site, remembered"), (.session, "Its site, until Sunset quits"),
                    (.page, "The page alone, saved with it")
                ],
                label: "A page's zoom applies to"
            ),
            custom("web.textOnlyZoom", "Zoom text only", "zoom text font", .textOnlyZoom)
        ]
}
