extension SettingsOption {
    /// Updates of Sunset and its components (roadmap 0122, n135): the versions, then the two switches.
    static let updates: [Self] = [
        custom("updates.center", "Versions", "update version release notes check install components", .updates)
            .setting([]),
        updateSwitch(
            "updates.automatic",
            \.updates.automatic,
            "Update automatically",
            "auto download install quit",
            "Download updates and install them when Sunset quits"
        ),
        updateSwitch(
            "updates.prereleases",
            \.updates.prereleases,
            "Take pre-releases",
            "pre-release alpha beta channel",
            "Offer alpha and beta releases"
        )
    ]

    /// A switch of `updates.*`.
    private static func updateSwitch(
        _ key: String,
        _ path: Path<Bool>,
        _ title: String,
        _ words: String,
        _ label: String
    )
        -> Self
    {
        toggle(key, title, "update " + words, path, label: label)
    }
}
