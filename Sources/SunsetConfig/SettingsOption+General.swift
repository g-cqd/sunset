/// The options of General, and of Privacy and security.
extension SettingsOption {
    /// Startup, closing and quitting.
    static let startup: [Self] =
        [
            toggle("tabs.restore", "Restore tabs at launch", "session reopen quit windows", \.tabs.restore)
                .noted(
                    "The windows, tabs and splits come back, each pane as a new shell in the directory it was in. Programs "
                        + "that were running are not restarted."
                ),
            toggle(
                "tabs.confirmClose",
                "Confirm closing a tab with a running command",
                "close warn running red",
                \.tabs.confirmClose,
                label: "Confirm closing a busy tab"
            )
            .noted(
                "When a foreground command is running, the first click on the close button or \u{2318}W tints the tab red; "
                    + "a second one closes it."
            ),
            choice(
                "tabs.askBeforeQuit",
                "Ask before quitting",
                "quit confirm running lost form",
                \.tabs.askBeforeQuit,
                [(.never, "Never"), (.whenLosing, "When something would be lost"), (.always, "Always")]
            ),
            toggle(
                "tabs.keepRunningForFavorites",
                "Keep running while a favourite is open",
                "quit last window favorites background dock",
                \.tabs.keepRunningForFavorites
            )
            .noted(
                "Closing the last window does not quit Sunset while something in Favorites is open; it goes on running, and "
                    + "a new window shows it again."
            )
        ]

    /// The configuration file.
    static let configurationFile: [Self] =
        [
            custom("file.location", "Location", "path json config reveal editor errors problems", .fileLocation)
                .setting([])
        ]

    /// What a program in a terminal may do.
    static let programs: [Self] =
        [
            toggle(
                "terminal.clipboardWrite",
                "Programs may copy",
                "clipboard osc 52 pasteboard ssh",
                \.terminal.clipboardWrite,
                label: "Programs may copy to the clipboard"
            )
            .noted("What a program asks to copy (OSC 52), over ssh too. No program can read the clipboard.")
        ]

    /// What is kept of the web.
    static let browsing: [Self] =
        [
            choice(
                "web.historyKeep",
                "Keep history for",
                "history remove days",
                \.web.historyKeep,
                [
                    (.day, "One day"), (.week, "One week"), (.twoWeeks, "Two weeks"), (.month, "One month"),
                    (.year, "One year"), (.forever, "Always")
                ],
                label: "Keep the history of pages for"
            ),
            toggle(
                "web.clearHistoryOnQuit",
                "Clear history when Sunset quits",
                "history quit privacy",
                \.web.clearHistoryOnQuit,
                label: "Clear the history when Sunset quits"
            ),
            toggle(
                "web.clearWebsiteDataOnQuit",
                "Clear website data when Sunset quits",
                "cookies cache quit privacy",
                \.web.clearWebsiteDataOnQuit,
                label: "Clear website data when Sunset quits (signs you out of sites)"
            ),
            toggle(
                "web.privateWindowShares",
                "Private windows share their data",
                "private incognito store cookies",
                \.web.privateWindowShares,
                label:
                    "The pages of a new private window share their data (a private tab of a normal window never does)"
            )
        ]
}
