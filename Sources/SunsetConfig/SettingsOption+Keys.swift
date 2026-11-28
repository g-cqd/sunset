extension SettingsOption {
    /// The commands' keys: each command of the menus with its key, recorded by pressing it.
    static let keys: [Self] =
        [
            custom(
                "keys",
                "Commands' keys",
                "keys keyboard shortcuts hotkeys bindings commands menus record",
                .keys
            )
            .setting(["keys"])
            .noted(
                "Click a key and press the new one, then a second for two keys or Return for one; Delete takes it away. "
                    + "A key another command has is moved to this one."
            )
        ]
}
