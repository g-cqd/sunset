/// The options of General, and of Privacy and security.
extension SettingsOption {
    /// Startup, closing and quitting.
    static let startup: [Self] =
        [
            toggle("tabs.restore", "Restore tabs at launch", "session reopen quit windows", \.tabs.restore)
                .noted(
                    "The windows, tabs and splits come back, each pane as a new shell in the directory it was in. Programs "
                        + "that were running are not restarted."
                )
                .grouped("Launch"),
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
            )
            .grouped("Closing a tab"),
            toggle(
                "tabs.closeGoesBack",
                "Show the previous tab after closing one",
                "close tab previous recent last neighbour back",
                \.tabs.closeGoesBack
            )
            .noted("Off, the tab next to the closed one is shown.")
            .grouped("Closing a tab"),
            toggle(
                "tabs.closeWindowWithLastTab",
                "Close the window with its last tab",
                "last tab close window empty space stay",
                \.tabs.closeWindowWithLastTab
            )
            .noted("Off, a window stays open, empty, when the last tab of its Space closes.")
            .grouped("Closing a tab"),
            toggle(
                "tabs.keepRunningForFavorites",
                "Keep running while a favorite is open",
                "quit last window favorites background dock",
                \.tabs.keepRunningForFavorites
            )
            .noted(
                "Closing the last window does not quit Sunset while something in Favorites is open; it goes on running, and "
                    + "a new window shows it again."
            )
            .grouped("Closing the last window"),
            toggle(
                "tabs.closeWithLastWindow",
                "Close the tabs with the last window",
                "last window close tabs keep stop space red button",
                \.tabs.closeWithLastWindow
            )
            .noted(
                "Off, closing the last window stops what runs in its tabs and keeps them: the next window, or the next "
                    + "launch, has them again, each started from where it was."
            )
            .grouped("Closing the last window"),
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
            .noted("Tabs kept after the last window closed are closed once this long has passed; 0 is never.")
            .grouped("Closing the last window"),
            choice(
                "tabs.askBeforeQuit",
                "Ask before quitting",
                "quit confirm running lost form",
                \.tabs.askBeforeQuit,
                [(.never, "Never"), (.whenLosing, "When something would be lost"), (.always, "Always")]
            )
            .noted("Edits to a file that are not saved are asked about whatever this says.")
            .grouped("Quitting"),
            toggle(
                "tabs.keepAwakeDisplay",
                "Keep the display on with the Mac",
                "awake sleep caffeinate display screen power keep",
                \.tabs.keepAwakeDisplay
            )
            .noted("A tab or a window kept awake keeps the screen on too; off, only the Mac stays awake.")
            .grouped("Keeping awake")
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
            .noted("What a program asks to copy (OSC 52), over SSH too. No program can read the clipboard."),
            choice(
                "terminal.secureKeyboard",
                "Secure keyboard entry",
                "secure keyboard keylogger password sudo event tap",
                \.terminal.secureKeyboard,
                [(.whenPassword, "While a password is asked"), (.always, "Always"), (.off, "Never")]
            )
            .noted(
                "Other apps cannot read what you type in the terminal. A password asked on another computer through SSH is "
                    + "not seen: choose Always for those."
            ),
            toggle(
                "terminal.pasteWarning",
                "Ask before a risky paste",
                "paste warning newline commands control hidden characters",
                \.terminal.pasteWarning,
                label: "Ask before pasting text that runs commands or hides characters"
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
                "Imported plain files",
                "import old files trash delete plain legacy",
                \.storage.importedFiles,
                [(.trash, "Move to Trash"), (.delete, "Delete immediately")]
            )
            .noted(
                "The plain files of before sealing, once what they held is sealed. In the Trash they are readable until it is "
                    + "emptied."
            )
        ]
}
