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
            )
            .noted("Edits to a file that are not saved are asked about whatever this says."),
            toggle(
                "tabs.keepRunningForFavorites",
                "Keep running while a favourite is open",
                "quit last window favorites background dock",
                \.tabs.keepRunningForFavorites
            )
            .noted(
                "Closing the last window does not quit Sunset while something in Favorites is open; it goes on running, and "
                    + "a new window shows it again."
            ),
            toggle(
                "tabs.closeWithLastWindow",
                "Close the tabs with the last window",
                "last window close tabs keep stop space red button",
                \.tabs.closeWithLastWindow
            )
            .noted(
                "Off, closing the last window stops what runs in its tabs and keeps them: the next window, or the next "
                    + "launch, has them again, each started from where it was."
            ),
            number(
                "tabs.closeStoppedAfter",
                "Close tabs left without a window after",
                "last window stopped tabs clean delay hours forget space",
                \.tabs.closeStoppedAfter,
                0 ... 8760,
                step: 1,
                unit: "h",
                digits: 0
            )
            .noted("Tabs kept after the last window closed are closed once this long has passed; 0 is never."),
            toggle(
                "tabs.closeWindowWithLastTab",
                "Close the window with its last tab",
                "last tab close window empty space stay",
                \.tabs.closeWindowWithLastTab
            )
            .noted("Off, a window stays open, empty, when the last tab of its Space closes."),
            toggle(
                "tabs.keepAwakeDisplay",
                "Keep the display on with the Mac",
                "awake sleep caffeinate display screen power keep",
                \.tabs.keepAwakeDisplay
            )
            .noted("A tab or a window kept awake keeps the screen on too; off, only the Mac stays awake.")
        ]

    /// When a file is written by itself, and how its source looks.
    static let documents: [Self] =
        [
            number(
                "documents.saveAfter",
                "Save a file by itself after",
                "autosave document markdown timer seconds write edits",
                \.documents.saveAfter,
                0 ... 3600,
                step: 1,
                unit: "s",
                digits: 0
            )
            .noted(
                "A file is written this long after its first unsaved edit; 0 is never. It is never written over a change "
                    + "made elsewhere, and a deleted file is not made again."
            ),
            toggle(
                "documents.saveOnFocusLoss",
                "Save a file when it loses focus",
                "autosave document markdown focus switch pane app background",
                \.documents.saveOnFocusLoss
            )
            .noted(
                "When another pane takes the keyboard, or another app comes to the front. A document that has no file is "
                    + "always kept by Sunset, whatever these say."
            ),
            toggle(
                "documents.largerHeadings",
                "Show headings larger in the source",
                "markdown source editor heading size font page look rendered",
                \.documents.largerHeadings
            )
            .noted("A heading's text is at the size the page gives it; off, every line of the source has one height.")
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
