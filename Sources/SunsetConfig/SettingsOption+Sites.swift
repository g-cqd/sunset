extension SettingsOption {
    /// Every site with something of its own: kept sealed, not in the file.
    static let sites: [Self] =
        [
            custom(
                "web.sites",
                "Sites with settings of their own",
                "site each own forget rules permissions zoom space blocking paused agent",
                .sites
            )
            .setting([])
        ]
}
