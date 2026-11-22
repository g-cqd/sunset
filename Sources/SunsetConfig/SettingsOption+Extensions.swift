extension SettingsOption {
    /// Each profile's extensions: kept in the profile's folder, not in the file.
    static let extensions: [Self] =
        [
            custom(
                "web.extensions",
                "Installed extensions",
                "extension extensions add-on addon chrome firefox store install private",
                .extensions
            )
            .setting([])
            .noted("Each profile has its own. What an extension may do is granted when it is installed.")
        ]
}
