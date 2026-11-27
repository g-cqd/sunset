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
        ),
        .controlFromOutside: HelpEntry(
            title: "Control from outside",
            summary: "Driven by the sunset tool: click to stop it for this pane.",
            text: [
                "With **Settings > General > Control from outside** on, programs you run can list and read the panes "
                    + "and run the menus' commands with the `sunset` tool, or as an MCP server with `sunset mcp`.",
                "The first request of each session (a terminal's shell, an app that started the tool) asks you; your "
                    + "answer holds until that session ends or Sunset quits. Typing into terminals is a switch of its own.",
                "A pane being driven shows a mark on its tab: click it, and the tool is refused that pane."
            ],
            related: [.features]
        )
    ]
}
