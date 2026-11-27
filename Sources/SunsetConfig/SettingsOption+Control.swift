extension SettingsOption {
    /// The control socket and what it may do (ADR-0129).
    static let control: [Self] = [
        toggle(
            "control.enabled",
            "Control from outside",
            "control socket sunset tool command line cli automation script agent mcp",
            \.control.enabled,
            label: "Answer the sunset tool"
        )
        .noted(
            "Programs you run can list and read the panes and run the menus' commands with the sunset tool, over a "
                + "socket only your user can open."
        ),
        toggle(
            "control.typing",
            "Typing into terminals",
            "control socket type keys terminal automation agent",
            \.control.typing,
            label: "Let the sunset tool type into terminals"
        )
        .noted("What it types runs as if you typed it.")
    ]
}
