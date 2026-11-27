extension SettingsOption {
    /// The control socket and what it may do (ADR-0129).
    static let control: [Self] = [
        controlSwitch(
            ("control.enabled", \.control.enabled),
            "Control from outside",
            "socket sunset tool command line cli automation script mcp",
            label: "Answer the sunset tool",
            note: "Programs you run can list and read the panes and run the menus' commands with the sunset tool, over "
                + "a socket only your user can open."
        ),
        controlSwitch(
            ("control.typing", \.control.typing),
            "Typing into terminals",
            "type keys terminal",
            label: "Let the sunset tool type into terminals",
            note: "What it types runs as if you typed it."
        )
    ]

    private static func controlSwitch(
        _ setting: (key: String, path: Path<Bool>),
        _ title: String,
        _ words: String,
        label: String,
        note: String
    ) -> Self {
        toggle(setting.key, title, "control agent " + words, setting.path, label: label).noted(note)
    }
}
