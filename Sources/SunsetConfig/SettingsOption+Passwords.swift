extension SettingsOption {
    /// When the vault locks (the owner, 2026-11-23); sleep, the screen locking, quitting and the last window closing lock
    /// it whatever these say.
    static let passwords: [Self] = [
        number(
            "passwords.lockAfter",
            "Lock after",
            lockWords,
            \.passwords.lockAfter,
            0 ... 240,
            step: 1,
            unit: "min",
            digits: 0
        )
        .noted("Minutes without use. 0: only when the Mac sleeps, the screen locks, or Sunset quits."),
        lockSwitch(
            "passwords.lockOnLeavingTab",
            \.passwords.lockOnLeavingTab,
            "Lock on leaving the tab",
            "tab switch leave"
        ),
        lockSwitch(
            "passwords.lockOnWindowBlur",
            \.passwords.lockOnWindowBlur,
            "Lock with the window",
            "window focus blur"
        )
    ]

    private static let lockWords = "vault passwords lock idle minutes timeout auto"

    /// A switch that locks the vault on leaving something; its label says when.
    private static func lockSwitch(_ key: String, _ path: Path<Bool>, _ title: String, _ words: String) -> Self {
        let when = key.hasSuffix("Tab") ? "another tab of the window is chosen" : "its window is no longer in front"
        return toggle(key, title, "vault passwords lock " + words, path, label: "Lock when " + when)
    }
}
