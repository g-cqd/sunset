import SunsetPane

extension AppCommand {
    /// Every command, in the menus' order.
    package static let table: [Self] = file + view + panes + window + spaces + history + places

    private static let file: [Self] = [
        Self(.newWindow, "New Window", "macwindow.badge.plus", "File", key: KeyChord("n")),
        Self(.newTab, "New Tab", "plus.square", "File", key: KeyChord("t")),
        Self(
            .newTabOfKind,
            "New Tab of Kind\u{2026}",
            "plus.square.on.square",
            "File",
            key: KeyChord("t", [.command, .shift]),
            words: ["terminal", "page", "kind"]
        ),
        Self(
            .newPrivateWindow,
            "New Private Window",
            "hand.raised.square",
            "File",
            key: KeyChord("n", [.command, .shift]),
            scope: .web,
            words: ["incognito"]
        ),
        Self(
            .newPrivateTab,
            "New Private Tab",
            "hand.raised",
            "File",
            key: KeyChord("n", [.command, .shift, .option]),
            scope: .web,
            words: ["incognito"]
        ),
        Self(.newDocument, "New Document", "doc.badge.plus", "File", scope: .documents, words: ["markdown", "note"]),
        Self(.openFile, "Open File\u{2026}", "folder", "File", key: KeyChord("o"), scope: .documents),
        Self(.closeTab, "Close Tab", "xmark.square", "File", key: KeyChord("w")),
        Self(.closeOtherTabs, "Close Other Tabs", "xmark.square.fill", "File", key: KeyChord("w", [.command, .option])),
        Self(.closeWindow, "Close Window", "xmark.rectangle", "File", key: KeyChord("w", [.command, .shift])),
        Self(.print, "Print\u{2026}", "printer", "File", key: KeyChord("p"), scope: .web),
        Self(
            .importFromBrowser,
            "Import from Another Browser\u{2026}",
            "square.and.arrow.down",
            "File",
            scope: .web,
            words: ["bookmarks", "chrome", "firefox", "safari", "extensions"]
        )
    ]

    private static let view: [Self] = [
        Self(.commandBar, "Command Bar", "magnifyingglass", "Edit", key: KeyChord("l"), inBar: false),
        Self(
            .zoomIn,
            "Zoom In",
            "plus.magnifyingglass",
            "View",
            key: KeyChord("+"),
            words: ["bigger", "larger", "font"]
        ),
        Self(.zoomOut, "Zoom Out", "minus.magnifyingglass", "View", key: KeyChord("-"), words: ["smaller", "font"]),
        Self(
            .actualSize,
            "Actual Size",
            "1.magnifyingglass",
            "View",
            key: KeyChord("0"),
            words: ["reset", "zoom", "font"]
        ),
        Self(
            .previousPrompt,
            "Previous Prompt",
            "arrow.up.to.line",
            "View",
            key: KeyChord(.up),
            scope: .terminal,
            words: ["command", "jump"]
        ),
        Self(
            .nextPrompt,
            "Next Prompt",
            "arrow.down.to.line",
            "View",
            key: KeyChord(.down),
            scope: .terminal,
            words: ["command", "jump"]
        )
    ]

    private static let panes: [Self] = [
        Self(
            .splitRight,
            "Split Right",
            "rectangle.split.2x1",
            "Panes",
            key: KeyChord("d"),
            words: ["vertical", "side"]
        ),
        Self(
            .splitDown,
            "Split Down",
            "rectangle.split.1x2",
            "Panes",
            key: KeyChord("d", [.command, .shift]),
            words: ["horizontal", "below"]
        ),
        Self(.nextPane, "Next Pane", "arrow.right.square", "Panes", key: KeyChord("]", [.command, .option])),
        Self(.previousPane, "Previous Pane", "arrow.left.square", "Panes", key: KeyChord("[", [.command, .option])),
        Self(
            .movePaneToTab,
            "Move Pane to Its Own Tab",
            "rectangle.portrait.and.arrow.right",
            "Panes",
            words: ["separate"]
        ),
        Self(.renameTab, "Rename Tab\u{2026}", "pencil", "Panes", words: ["name", "title"]),
        Self(.togglePinned, "Pin or Unpin Tab", "pin", "Panes"),
        Self(.toggleFavorite, "Add to or Remove from Favorites", "star", "Panes", words: ["favourite", "keep"])
    ]

    private static let window: [Self] = [
        Self(.nextTab, "Show Next Tab", "chevron.right.square", "Window", key: KeyChord("]", [.command, .shift])),
        Self(.previousTab, "Show Previous Tab", "chevron.left.square", "Window", key: KeyChord("[", [.command, .shift]))
    ]

    private static let spaces: [Self] = [
        Self(.newSpace, "New Space", "square.stack.3d.up.badge.plus", "Spaces", words: ["workspace"]),
        Self(.editSpace, "Edit Space\u{2026}", "square.and.pencil", "Spaces", words: ["workspace", "colour", "color"]),
        Self(.deleteSpace, "Delete Space\u{2026}", "trash", "Spaces", words: ["remove", "workspace"]),
        Self(
            .nextSpace,
            "Show Next Space",
            "arrow.right.circle",
            "Spaces",
            key: KeyChord(.right, [.command, .option]),
            words: ["workspace"]
        ),
        Self(
            .previousSpace,
            "Show Previous Space",
            "arrow.left.circle",
            "Spaces",
            key: KeyChord(.left, [.command, .option]),
            words: ["workspace"]
        )
    ]

    private static let history: [Self] = [
        Self(.back, "Back", "chevron.backward", "History", key: KeyChord("["), scope: .web, words: ["page"]),
        Self(.forward, "Forward", "chevron.forward", "History", key: KeyChord("]"), scope: .web, words: ["page"]),
        Self(.reload, "Reload Page", "arrow.clockwise", "History", key: KeyChord("r"), scope: .web, words: ["refresh"]),
        Self(
            .reloadWithoutCache,
            "Reload Page Without Cache",
            "arrow.clockwise.circle",
            "History",
            key: KeyChord("r", [.command, .shift]),
            scope: .web,
            words: ["refresh", "hard"]
        ),
        Self(
            .forceReload,
            "Force Reload Page",
            "exclamationmark.arrow.circlepath",
            "History",
            key: KeyChord("r", [.command, .option]),
            scope: .web,
            words: ["refresh", "hung", "stuck"]
        ),
        Self(.toggleMute, "Mute or Unmute Page", "speaker.slash", "History", scope: .web, words: ["sound", "audio"]),
        Self(.stop, "Stop Loading", "xmark", "History", key: KeyChord("."), scope: .web),
        Self(.openAddress, "Open Address", "link", "History", scope: .web, words: ["url", "location"]),
        Self(
            .toggleInspector,
            "Show or Hide Web Inspector",
            "hammer",
            "History",
            key: KeyChord("i", [.command, .option]),
            scope: .web,
            words: ["developer", "devtools", "console"]
        )
    ]

    private static let places: [Self] = [
        Self(.library, "Library", "books.vertical", "Sidebar"),
        Self(.documents, "Documents", "doc.text", "Library", scope: .documents, words: ["files", "notes"]),
        Self(.history, "History", "clock", "Library", scope: .web, words: ["visited"]),
        Self(.downloads, "Downloads", "arrow.down.circle", "Library", scope: .web),
        Self(
            .passwords,
            "Passwords",
            "key",
            "Library",
            scope: .passwords,
            words: ["vault", "logins", "keys", "cards"]
        ),
        Self(
            .settings,
            "Settings",
            "gearshape",
            "Sunset",
            key: KeyChord(","),
            words: ["preferences", "options", "configuration"]
        ),
        Self(
            .help,
            "Sunset Help",
            "questionmark.circle",
            "Help",
            key: KeyChord("?"),
            words: ["manual", "documentation", "shortcuts"]
        )
    ]
}
