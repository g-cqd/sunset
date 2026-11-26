/// Session restore policy & terminal history encryption options (roadmap 0024 S-3, S-4).
extension SettingsOption {
    static var sessionRestore: [Self] {
        [
            Self.makeRestorePolicyOption(),
            Self.makeRestoreSwitch(
                key: "tabs.restoreTerminalHistory",
                title: "Restore terminal screens & scrollback",
                keywords: "session terminal scrollback history screen replay divider",
                note: "Replays saved screen and scrollback lines above a divider line before starting a fresh shell.",
                path: \.tabs.restoreTerminalHistory
            ),
            Self.makeRestoreSwitch(
                key: "storage.encryptTerminalHistory",
                title: "Encrypt saved terminal history",
                keywords: "storage seal keychain encrypt terminal scrollback history at rest",
                note: "Seals saved terminal snapshots on disk with Sunset\u{2019}s Keychain storage key.",
                path: \.storage.encryptTerminalHistory
            )
        ]
    }

    private static func makeRestorePolicyOption() -> Self {
        let items: [(Configuration.Tabs.RestorePolicy, String)] = [
            (.always, "Always"),
            (.ask, "Ask at launch"),
            (.never, "Never")
        ]
        return choice(
            "tabs.restorePolicy",
            "Restore session policy",
            "session launch restore always ask never crash",
            \.tabs.restorePolicy,
            items
        )
        .noted("After a crash Sunset always asks before restoring your previous session.")
        .grouped("Launch")
    }

    private static func makeRestoreSwitch(
        key: String,
        title: String,
        keywords: String,
        note: String,
        path: any WritableKeyPath<Configuration, Bool> & Sendable
    ) -> Self {
        toggle(key, title, keywords, path).noted(note).grouped("Launch")
    }
}
