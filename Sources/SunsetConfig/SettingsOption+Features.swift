extension SettingsOption {
    /// The scopes of the app (roadmap 0033; ADR-0056): three switches, drawn by the app, which asks before closing what
    /// is open of a scope.
    static let features: [Self] =
        [
            custom(
                "features",
                "Terminals, the web, documents",
                "features scope remove disable turn off terminal web browser documents markdown only",
                .features
            )
            .setting(["features.terminal", "features.web", "features.documents"])
            .noted(
                "Turning one off removes it from Sunset: its menus, its settings, its tabs (closed after a question) "
                    + "and what is kept of it, which is hidden and comes back when it is turned on again. Its data is "
                    + "kept untouched. At least one stays on."
            )
        ]
}
