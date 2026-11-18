import SunsetMetrics

/// The options of Tabs and sidebar; the numbers of the layout that measure them are added in `SettingsSection`.
extension SettingsOption {
    /// Where the tabs are.
    static let placement: [Self] =
        [
            choice(
                "tabs.mode",
                "Tabs",
                "native internal built-in none windows",
                \.tabs.mode,
                [
                    (.none, "None"), (.native, "Native"),
                    (.internal, "Built-in")
                ]
            )
            .noted(
                "Native tabs are the system's; built-in tabs are a bar in the window; none is one terminal per window."
            )
            .grouped("Tabs"),
            choice(
                "tabs.bar.position",
                "Built-in bar position",
                "top bottom internal",
                \.tabs.bar.position,
                [(.top, "Top"), (.bottom, "Bottom")]
            )
            .grouped("Tabs"),
            toggle("sidebar.enabled", "Show the sidebar", "tabs vertical list", \.sidebar.enabled)
                .noted("The sidebar lists the tabs. It needs tabs set to Native (the built-in bar replaces it).")
                .grouped("Sidebar"),
            choice(
                "sidebar.side",
                "Side",
                "left right edge mirror",
                \.sidebar.side,
                [(.left, "Left"), (.right, "Right")]
            )
            .grouped("Sidebar"),
            toggle(
                "sidebar.autoHide",
                "Hide the sidebar",
                "float hover pin reveal auto",
                \.sidebar.autoHide,
                label: "Hide the sidebar until the pointer reaches its edge"
            )
            .noted("The same as the pin at the top of the sidebar.")
            .grouped("Sidebar"),
            number("sidebar.width", "Width", "size wide", \.sidebar.width, 120 ... 480, step: 5)
                .grouped("Sidebar")
        ]

    static let labels: [Self] =
        [
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
            toggle("tabs.bar.progress", "Show progress", "tab bar osc 9 download", \.tabs.bar.showProgress),
            choice(
                "web.tabIcon",
                "Page tab icon",
                "icon globe letter favicon",
                \.web.tabIcon,
                [(.favicon, "Site icon"), (.initial, "First letter of the title"), (.globe, "Globe")]
            )
        ]

    /// The Library and the documents.
    static let library: [Self] =
        [
            toggle(
                "sidebar.separators",
                "Section separators",
                "line divider pinned favorites tabs separator",
                \.sidebar.separators,
                label: "Show lines between Pinned, Favorites and tabs"
            )
            .noted("Off, the sections keep their space without a line."),
            toggle(
                "sidebar.previews",
                "Previews",
                "preview card hover thumbnail picture",
                \.sidebar.previews,
                label: "Show a preview when pointing at a tab"
            ),
            toggle("sidebar.previewPages", "Previews of pages", "preview web page site", \.sidebar.previewPages)
                .further,
            toggle(
                "sidebar.previewTerminals",
                "Previews of terminals",
                "preview terminal shell",
                \.sidebar.previewTerminals
            )
            .further,
            toggle(
                "sidebar.previewDocuments",
                "Previews of documents",
                "preview document markdown note",
                \.sidebar.previewDocuments
            )
            .further,
            toggle(
                "sidebar.previewFolders",
                "Previews of folders",
                "preview folder favorites list",
                \.sidebar.previewFolders
            )
            .further,
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
            choice(
                "sidebar.documentSort",
                "Order of documents",
                "sort latest name kind changed",
                \.sidebar.documentSort,
                [(.changed, "Latest Changed"), (.made, "Latest Made"), (.name, "Name"), (.kind, "Kind")]
            )
        ]
}
