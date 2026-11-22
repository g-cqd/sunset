extension HelpCatalog {
    /// What **Settings > General** sets that a note under a setting cannot say whole.
    static let general: [HelpTopic: HelpEntry] = [
        .features: HelpEntry(
            title: "Turning features off",
            summary: "Terminals, the web and documents can each be turned off; Sunset then shows nothing of them.",
            text: [
                "**Settings > General > Features** has a switch for each. Turning one off asks first when tabs of it are "
                    + "open, then closes them; its menus, settings, tabs and Favorites are hidden.",
                "Nothing is deleted: history, website data, documents and the Favorites of a feature come back when it "
                    + "is turned on again. At least one feature stays on."
            ],
            related: [.spaces]
        )
    ]
}
