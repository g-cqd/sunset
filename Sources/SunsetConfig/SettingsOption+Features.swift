extension SettingsOption {
    /// The scopes of the app: three switches, drawn by the app, which asks before closing what is open of a scope.
    static let features: [Self] =
        [
            custom(
                "features",
                "What Sunset does",
                "features scope remove disable turn off terminal web browser documents markdown only",
                .features
            )
            .setting(["features.terminal", "features.web", "features.documents", "features.credentials"])
            .noted(
                "Turning one off hides its menus, settings and tabs, which come back when it is turned on; its data is "
                    + "kept. At least one stays on."
            )
        ]
}
