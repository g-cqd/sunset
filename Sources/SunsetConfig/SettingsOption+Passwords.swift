extension SettingsOption {
    /// When the vault locks (the owner, 2026-11-23), how web sign-in fields fill, and automatic backups.
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
        .noted("Minutes without use. 0: only when the Mac sleeps, the screen locks, or Sunset quits.")
        .grouped("Locking"),
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
        ),
        fillSwitch(
            "passwords.autoFill",
            \.passwords.autoFill,
            "Fill on load",
            "autofill automatic fill load",
            label: "Fill a sign-in form as its page loads",
            note: "Only over HTTPS, only when the site has one login, saved for that very address."
        ),
        fillSwitch(
            "passwords.offerUnlock",
            \.passwords.offerUnlock,
            "Offer to unlock on fields",
            "unlock prompt field email totp",
            label: "Offer to unlock Passwords when clicking a sign-in, email or code field",
            note: "Shows an unlock row under the field while Passwords are locked, then lists matching entries."
        ),
        backupFolderOption.grouped("Backups"),
        backupKeepOption.grouped("Backups")
    ]

    private static let backupFolderOption = text(
        "passwords.backupFolder",
        "Automatic backup folder",
        "vault passwords backup svault automatic folder path",
        \.passwords.backupFolder,
        prompt: "Off (choose a folder path)"
    )
    .noted("Writes a sealed .svault backup to this folder when Sunset quits. Leave empty to turn off.")

    private static let backupKeepOption = number(
        "passwords.backupKeep",
        "Keep backups",
        "vault passwords backup svault retain count rotate",
        \.passwords.backupKeep,
        1 ... 100,
        step: 1,
        unit: "files",
        digits: 0
    )
    .noted("Older automatic .svault backups in the backup folder are removed past this count.")

    private static let lockWords = "vault passwords lock idle minutes timeout auto"

    /// A switch that locks the vault on leaving something; its label says when.
    private static func lockSwitch(_ key: String, _ path: Path<Bool>, _ title: String, _ words: String) -> Self {
        let when = key.hasSuffix("Tab") ? "another tab of the window is chosen" : "its window is no longer in front"
        return toggle(key, title, "vault passwords lock " + words, path, label: "Lock when " + when)
            .grouped("Locking")
    }

    private static func fillSwitch(
        _ key: String,
        _ path: Path<Bool>,
        _ title: String,
        _ words: String,
        label: String,
        note: String
    ) -> Self {
        toggle(key, title, "vault passwords sign in login " + words, path, label: label)
            .noted(note + " Never in a private window.")
            .grouped("Filling in pages")
    }
}
