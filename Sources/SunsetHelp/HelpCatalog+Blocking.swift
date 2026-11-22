extension HelpCatalog {
    /// Blocking ads and trackers.
    static let blocking: [HelpTopic: HelpEntry] = [
        .blocking: HelpEntry(
            title: "Blocking ads and trackers",
            summary: "Pages load without the ads and trackers that EasyList and EasyPrivacy name.",
            text: [
                "Sunset fetches the lists itself every few days, from the addresses in **Settings > Web > Blocking**: the "
                    + "only requests it makes on its own. A list can hide parts of a page or stop what it loads, nothing "
                    + "else.",
                "A site that breaks can be let through: its panel in the address field has \"Block ads and trackers\", "
                    + "for the site and its subdomains. The page loads again."
            ],
            expert: [
                "What WebKit's blocker cannot do (regular expressions, rewritten responses, scripts a list would run) is "
                    + "left out; Settings says how many rules each list has in use and how many were left out."
            ],
            related: [.sitePermissions, .browserIdentity]
        )
    ]
}
