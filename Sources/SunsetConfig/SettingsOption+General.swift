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

    /// What is kept, and what protects it (R12 step ST-6).
    static let kept: [Self] =
        [
            custom(
                "storage.sealed",
                "Sealed with your key",
                "documents session history size sealed encrypted store",
                .storageSealed
            )
            .setting([]),
            custom(
                "storage.websiteData",
                "Website data",
                "cookies filevault encrypted clear website data not sealed disk",
                .storageWebsiteData
            )
            .setting([]),
            custom(
                "storage.setAside",
                "Files set aside",
                "damaged moved aside unreadable did not read",
                .storageSetAside
            )
            .setting([])
        ]

    /// The key and its recovery code.
    static let keyAndRecovery: [Self] =
        [
            custom("storage.key", "Recovery code", "key keychain recovery code backup show copy", .storageKey)
                .setting([]),
            custom(
                "storage.enterCode",
                "Enter a recovery code",
                "key restore another mac lost keychain",
                .storageEnterCode
            )
            .setting([])
        ]

    /// Out of the store.
    static let export: [Self] =
        [
            custom(
                "storage.export",
                "Export all",
                "export documents history csv session json backup plain files",
                .storageExport
            )
            .setting([]),
            choice(
                "storage.importedFiles",
                "Imported plain files go to",
                "import old files trash delete plain legacy",
                \.storage.importedFiles,
                [(.trash, "The Trash"), (.delete, "Deleted at once")],
                label: "Plain files Sunset has imported go to"
            )
            .noted(
                "The files of before sealing (a session, a history) once what they held is in the sealed store. In the Trash "
                    + "they are readable until it is emptied; deleted, no plain copy is left."
            )
        ]
}
