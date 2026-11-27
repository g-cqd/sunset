import AppIntents

/// What Spotlight and Siri offer without a shortcut made.
struct SunsetShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RunSunsetCommand(),
            phrases: ["Run \(\.$command) in \(.applicationName)", "\(.applicationName) \(\.$command)"],
            shortTitle: "Run Command",
            systemImageName: "command"
        )
    }
}
