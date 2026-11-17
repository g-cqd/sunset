extension HelpCatalog {
    /// The sidebar's controls (roadmap 0041 B).
    static let sidebar: [HelpTopic: HelpEntry] = [
        .tabs: HelpEntry(
            title: "Tabs",
            summary:
                "A row of the sidebar is a tab: a terminal, a page or a document, or several of them side by side.",
            text: [
                "Click a row to show its tab; ⌘-click or ⇧-click to select several, then drag or right-click them together.",
                "Today's tabs are those of this window's Space; they scroll, while the Pinned grid and the Favorites stay.",
                "Pointed at, a row shows its close button; a page's row also shows a picture of the page after a moment."
            ],
            related: [.splitTabs, .pinned, .favorites, .dragAndDrop]
        ),
        .splitTabs: HelpEntry(
            title: "Split tabs",
            summary:
                "A row holding several panes shows each as a part; click a part to show the tab with that pane focused.",
            text: [
                "Right-click a part for Move Pane to Its Own Tab: the pane leaves the split, still running.",
                "This works from Today's tabs, the Favorites and the Pinned grid alike."
            ],
            related: [.tabs, .dragAndDrop]
        ),
        .pinned: HelpEntry(
            title: "Pinned grid",
            summary:
                "Tiles at the top of the sidebar for the tabs you open all the time; they stay when you close them.",
            text: [
                "Pin a tab from its menu, or drag it onto the grid. A tile that is closed keeps its place and opens again "
                    + "when clicked.",
                "The grid belongs to the profile: every Space of a profile shows the same tiles."
            ],
            related: [.favorites, .dragAndDrop, .keepAwake]
        ),
        .favorites: HelpEntry(
            title: "Favorites",
            summary:
                "Tabs kept under the grid, in folders if you like; each opens where it was and closes back to its row.",
            text: [
                "Add a tab with Add to Favorites in its menu, or drag it into the Favorites. Remove from Favorites gives "
                    + "it back to Today's tabs.",
                "A favorite with a command runs it each time it starts; Edit Command… shows and changes it."
            ],
            expert: [
                "Closing the last window does not quit Sunset while a favorite is open, unless "
                    + "\"Keep running while a favorite is open\" is off in Settings."
            ],
            related: [.folders, .pinned, .dragAndDrop]
        ),
        .folders: HelpEntry(
            title: "Folders",
            summary: "Folders group favorites; they nest, fold away, and take any icon or name you give them.",
            text: [
                "New Folder in the Favorites' menu, or New Folder with This Tab in a tab's menu. Drag rows in and out.",
                "Click a folder to fold or unfold it; double-click its name to rename it."
            ],
            related: [.favorites, .renaming, .dragAndDrop]
        ),
        .sidebarField: HelpEntry(
            title: "Sidebar field",
            summary: "Search the web, enter an address, or go to an open tab, all from the field at the top (⌘L).",
            text: [
                "Typing shows what matches, open tabs and pages among them; Return takes the first.",
                "Under the field, a site's question waits for your answer, and what macOS has not allowed Sunset shows "
                    + "with a button to allow it."
            ],
            related: [.tabs, .library]
        ),
        .bottomBar: HelpEntry(
            title: "Bottom bar",
            summary: "The bar at the foot of the sidebar opens a new tab (+), switches Spaces and opens the Library.",
            text: [
                "Click + for a new tab; right-click it for a terminal, a page, a private tab, a document or a new Space.",
                "Once there is a second Space, its icons sit in the middle of the bar; each Space has its own tabs."
            ],
            related: [.library, .tabs]
        ),
        .library: HelpEntry(
            title: "Library",
            summary: "The Library holds your documents, history, downloads and settings, beside the tabs.",
            text: [
                "Open it from the books in the bottom bar; its rail switches between Tabs, Documents, History, Downloads "
                    + "and Settings.",
                "The arrow at its top closes it, pointing at the sidebar's edge."
            ],
            related: [.bottomBar, .sidebarField]
        ),
        .keepAwake: HelpEntry(
            title: "Keeping the Mac awake",
            summary: "A tab or a window can keep the Mac awake until it closes, or until its command ends.",
            text: [
                "Choose Keep Mac Awake in a tab's or a window's menu, then how long. A cup shows on the row while it lasts.",
                "Point at the row and click the cup to stop. A tab keeps it when it moves to the Favorites or the grid."
            ],
            expert: [
                "\"Keep the display on with the Mac\" in Settings keeps the screen lit too; off, only the Mac stays awake."
            ],
            related: [.tabs, .pinned]
        ),
        .dragAndDrop: HelpEntry(
            title: "Drag and drop",
            summary: "Drag rows to reorder them, or into the grid, the Favorites, a folder, another window or a split.",
            text: [
                "While you drag, the places that would take the rows light up: the gaps between rows, the grid, a pane.",
                "A tab dropped in a window of another profile moves there, and its pages load again as that profile's."
            ],
            related: [.tabs, .pinned, .favorites, .folders]
        ),
        .layoutLight: HelpEntry(
            title: "Laying out a tab",
            summary:
                "The fourth light lays the tab out: side by side, stacked, three columns, one large and two, or a grid.",
            text: [
                "Click it, or rest the pointer on it, and choose a shape. With too few panes, the tabs after this one join "
                    + "it; with too many, the extra panes become tabs after it.",
                "Its color is the system's accent, or blue when the accent is close to the other lights' colors."
            ],
            related: [.splitTabs, .tabs]
        ),
        .renaming: HelpEntry(
            title: "Renaming",
            summary: "Double-click a row's name, or choose Rename Tab… in its menu, to give it a name of your own.",
            text: [
                "The row itself becomes the field; Return keeps the name, Escape leaves it as it was. Clear the name to "
                    + "get the one Sunset gives back.",
                "The same menu picks an icon: a symbol, an emoji or a color."
            ],
            related: [.tabs, .folders]
        )
    ]
}
