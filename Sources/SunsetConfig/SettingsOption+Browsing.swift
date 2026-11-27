/// Web › History and site data: history, what the web keeps between runs, private windows, sharing a tab.
extension SettingsOption {
    /// What is kept of the web.
    static let browsing: [Self] =
        [
            choice(
                "web.historyKeep",
                "Remove history items",
                "history remove days",
                \.web.historyKeep,
                [
                    (.day, "After one day"), (.week, "After one week"), (.twoWeeks, "After two weeks"),
                    (.month, "After one month"), (.year, "After one year"), (.forever, "Manually")
                ]
            )
            .grouped("History"),
            toggle(
                "web.clearHistoryOnQuit",
                "Clear history when Sunset quits",
                "history quit privacy",
                \.web.clearHistoryOnQuit,
                label: "Clear the history when Sunset quits"
            )
            .grouped("History"),
            choice(
                "web.keep.siteData",
                "Website data",
                "cookies sign in website data local storage indexeddb service workers quit keep clear",
                \.web.keep.siteData,
                [(.keep, "Kept"), (.keepChosen, "Kept for the sites chosen"), (.clearOnQuit, "Cleared on quit")]
            )
            .perProfile
            .grouped("Between runs")
            .noted(
                "Cookies, sign-ins and what sites store. Kept for the sites chosen: a site is chosen from its panel, or by "
                    + "itself when a password is sent from it; the others are cleared when Sunset quits."
            ),
            choice(
                "web.keep.cache",
                "Cache",
                "cache disk network quit keep clear",
                \.web.keep.cache,
                [(.keep, "Kept"), (.clearOnQuit, "Cleared on quit")]
            )
            .perProfile
            .grouped("Between runs")
            .noted(
                "Pages and files fetched, with their addresses. Cleared, pages load from the network after a relaunch."
            ),
            choice(
                "web.keep.traces",
                "Traces of visits",
                "hsts tracking statistics http3 alternative services quit keep clear",
                \.web.keep.traces,
                [(.keep, "Kept"), (.clearOnQuit, "Cleared on quit")]
            )
            .perProfile
            .grouped("Between runs")
            .noted(
                "The sites that asked for HTTPS only, when each was last used and what follows it, how each answers over "
                    + "HTTP/3. Cleared, nothing you see is lost."
            ),
            toggle(
                "web.privateWindowShares",
                "Private windows share their data",
                "private incognito store cookies",
                \.web.privateWindowShares,
                label: "Share data between a private window's pages"
            )
            .grouped("Private windows")
            .noted("A private tab of a normal window never shares."),
            toggle(
                "web.shareOtherProfiles",
                "Offer other profiles' tabs to share",
                "share screen tab call",
                \.web.shareOtherProfiles
            )
            .grouped("Sharing a tab")
            .noted("A page asking to share the screen is offered its profile's tabs; with this, every profile's.")
        ]
}
