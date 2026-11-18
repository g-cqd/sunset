extension SettingsOption {
    /// Every site with something of its own (roadmap 0022 W-d): kept sealed, not in the file.
    static let sites: [Self] =
        [
            custom(
                "web.sites",
                "Sites",
                "site each own forget rules permissions zoom space blocking paused agent",
                .sites
            )
            .setting([])
        ]
}
