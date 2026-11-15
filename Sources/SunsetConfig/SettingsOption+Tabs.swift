import SunsetMetrics

/// The options of the Sidebar, Layout and Tabs panes.
extension SettingsOption {
    static let sidebar = pane(
        "sidebar",
        [
            toggle("sidebar.enabled", "Show the sidebar", "tabs vertical list", \.sidebar.enabled)
                .noted("The sidebar lists the tabs. It needs tabs set to Native (the built-in bar replaces it)."),
            choice(
                "sidebar.side",
                "Side",
                "left right edge mirror",
                \.sidebar.side,
                [(.left, "Left"), (.right, "Right")]
            ),
            toggle(
                "sidebar.autoHide",
                "Hide the sidebar",
                "float hover pin reveal auto",
                \.sidebar.autoHide,
                label: "The sidebar hides, and floats over the content when the pointer is at its edge"
            )
            .noted("The same as the pin at the top of the sidebar."),
            number("sidebar.width", "Width", "size wide", \.sidebar.width, 120 ... 480, step: 5),
            number(
                "sidebar.padding",
                "Space around the terminal",
                "padding margin gap",
                \.sidebar.padding,
                0 ... 16,
                step: 1
            ),
            toggle(
                "sidebar.library",
                "Library",
                "sections documents history downloads rail",
                \.sidebar.library,
                label: "Library at the foot of the sidebar"
            )
            .noted(
                "Its glyph widens the sidebar by a rail: Tabs, Documents, History, Downloads. The panel on the other side has "
                    + "the same lists (Cmd-Y)."
            ),
            toggle(
                "sidebar.documents",
                "Documents among the tabs",
                "heading section notes markdown",
                \.sidebar.documents
            )
            .noted(
                "A Documents heading between the Favorites and the tabs: a document's row is its tab while it is open."
            ),
            choice(
                "sidebar.documentSort",
                "Order of documents",
                "sort latest name kind changed",
                \.sidebar.documentSort,
                [(.changed, "Latest Changed"), (.made, "Latest Made"), (.name, "Name"), (.kind, "Kind")]
            )
        ]
    )

    /// Every metric of `layout.*`: the numbers come from `Configuration.Layout.fields`, so a new one shows up here without a
    /// line of its own.
    static let layout: [Self] = pane(
        "layout",
        Configuration.Layout.fields.map { field in
            let value = SettingsValue<Double>(
                get: { $0.layout[keyPath: field.path] },
                set: { $0.layout[keyPath: field.path] = $1 }
            )
            let words = (field.keywords + ["layout", "spacing", "padding", "margin", "radius"]).joined(separator: " ")
            return Self(
                "layout.\(field.key)",
                field.title,
                words,
                .number(value, field.range, step: field.step, unit: field.unit, digits: 2)
            )
        } + [
            Self(
                "layout.terminalRadius",
                "Terminal card corner radius",
                "rounding card layout window",
                .radius(SettingsValue(\.layout.terminalRadius))
            ),
            Self(
                "layout.panelRadius",
                "Floating sidebar corner radius",
                "rounding panel layout window",
                .radius(SettingsValue(\.layout.panelRadius))
            )
        ]
    )

    static let tabs = pane(
        "tabs",
        [
            choice(
                "tabs.mode",
                "Tabs",
                "native internal built-in none windows",
                \.tabs.mode,
                [
                    (.none, "None (one terminal per window)"), (.native, "Native (system tabs)"),
                    (.internal, "Built-in (a bar in the window)")
                ]
            ),
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
            ),
            choice(
                "tabs.bar.position",
                "Built-in bar position",
                "top bottom internal",
                \.tabs.bar.position,
                [(.top, "Top"), (.bottom, "Bottom")]
            ),
            toggle("tabs.bar.icon", "Show the folder or command icon", "tab glyph letter picture", \.tabs.bar.showIcon),
            toggle("tabs.bar.title", "Show the title", "tab name", \.tabs.bar.showTitle),
            toggle(
                "tabs.bar.directory",
                "Show the working directory",
                "tab folder path osc 7",
                \.tabs.bar.showDirectory
            ),
            toggle(
                "tabs.bar.monospacedDirectory",
                "Second line in monospace",
                "tab directory font mono",
                \.tabs.bar.monospacedDirectory
            ),
            toggle("tabs.bar.progress", "Show progress", "tab bar osc 9 download", \.tabs.bar.showProgress)
        ]
    )
}
