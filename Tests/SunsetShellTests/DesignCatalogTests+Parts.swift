import SunsetMetrics
import SunsetPane
import SwiftUI

@testable import SunsetShell

extension DesignCatalogTests {
    /// The sidebar's buttons in each state (the face, so that hover and pressed can be drawn), and the choice rows for comparison.
    var buttons: CatalogSheet {
        func face(_ symbol: String, pressed: Bool, filled: Bool = false, size: Double) -> AnyView {
            AnyView(
                SidebarIconButtonFace(
                    label: SidebarSymbol(name: symbol, filled: filled),
                    pressed: pressed,
                    metrics: SidebarButtonMetrics(size: CGSize(width: size, height: size), radius: size == 28 ? 7 : 5)
                )
            )
        }
        let choice = ChoiceRow(
            id: "a",
            glyph: .symbol("globe"),
            title: "example.com",
            subtitle: "Open page",
            accessory: "⌘1",
            actions: []
        )
        return CatalogSheet(
            title: "Icon buttons and choice rows",
            note:
                "The sidebar's buttons (the pin, the +, downloads): one face, the sidebar's size. Hover is drawn by the face itself and "
                + "cannot be forced here; pressed can. The command bar's rows are their own component (36 tall).",
            columns: [
                .init(
                    title: "Sidebar buttons",
                    examples: [
                        .init(label: "docked 28, rest", view: face("sidebar.left", pressed: false, size: 28)),
                        .init(label: "docked 28, pressed", view: face("sidebar.left", pressed: true, size: 28)),
                        .init(
                            label: "pinned (filled)",
                            view: face("sidebar.left", pressed: false, filled: true, size: 28)
                        ),
                        .init(label: "floating 24, rest", view: face("plus", pressed: false, size: 24)),
                        .init(label: "floating 24, pressed", view: face("plus", pressed: true, size: 24))
                    ]
                ),
                .init(
                    title: "Choice rows (command bar)",
                    examples: [
                        .init(label: "row", view: AnyView(ChoiceRowView(row: choice, selected: false))),
                        .init(
                            label: "row, keyboard's",
                            view: AnyView(
                                ChoiceRowView(row: choice, selected: true)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.accentColor)
                                    )
                            )
                        )
                    ]
                )
            ],
            width: 300
        )
    }

    /// A split tab's row and a folder's, today and with the proposed padding.
    func groups(_ layout: LayoutMetrics, _ proposed: LayoutMetrics) -> CatalogSheet {
        func split(_ layout: LayoutMetrics, selected: Bool) -> AnyView {
            let harness = TabsHarness()
            harness.tabs.newTab()
            if let first = harness.made.first {
                first.title = "zsh"
                harness.tabs.split(.right, with: FakeContent(), beside: first)
            }
            guard let item = harness.tabs.workspace.items.first else { return AnyView(EmptyView()) }
            return AnyView(SidebarGroupRow(item: item, tabs: harness.tabs, selected: selected, layout: layout))
        }
        func folder(_ layout: LayoutMetrics, collapsed: Bool) -> AnyView {
            let favorites = FavoritesModel()
            var id: Favorites.NodeID?
            favorites.edit { id = $0.addFolder(named: "Projects") }
            if collapsed, let id { favorites.edit { $0.setCollapsed(true, for: id) } }
            let harness = TabsHarness(favorites: favorites)
            guard let id, let found = favorites.favorites.folder(id) else { return AnyView(EmptyView()) }
            return AnyView(FolderRow(tabs: harness.tabs, folder: found, layout: layout))
        }
        return CatalogSheet(
            title: "Split tabs and folders",
            note:
                "A split tab's row holds a sub-row per pane; a folder of the Favorites. Proposed: the same vertical padding as the tabs.",
            columns: [
                .init(
                    title: "Today",
                    examples: [
                        .init(label: "split", view: split(layout, selected: false)),
                        .init(label: "split selected", view: split(layout, selected: true)),
                        .init(label: "folder open", view: folder(layout, collapsed: false)),
                        .init(label: "folder closed", view: folder(layout, collapsed: true))
                    ]
                ),
                .init(
                    title: "Proposed",
                    examples: [
                        .init(label: "split", view: split(proposed, selected: false)),
                        .init(label: "split selected", view: split(proposed, selected: true)),
                        .init(label: "folder open", view: folder(proposed, collapsed: false)),
                        .init(label: "folder closed", view: folder(proposed, collapsed: true))
                    ]
                )
            ],
            width: 221
        )
    }
}

extension DesignCatalogTests {
    /// The Favorites of the catalog's app shots: an open folder with a page and a terminal, a closed folder, an entry at the top level.
    static func catalogFavorites() -> SavedFavorites {
        var favorites = Favorites()
        func home(_ kind: String, _ state: [String: String] = [:]) -> Favorites.Home {
            let pane = PaneID()
            return Favorites.Home(
                layout: .pane(pane),
                focused: pane,
                contents: [pane: PaneDescriptor(kind: kind, state: state)]
            )
        }
        let projects = favorites.addFolder(named: "Projects")
        _ = favorites.addEntry(
            home: home("web", ["url": "http://127.0.0.1:8766/form.html"]),
            title: "Form",
            in: projects
        )
        _ = favorites.addEntry(home: home("terminal"), title: "Build", in: projects)
        if let archive = favorites.addFolder(named: "Archive") { favorites.setCollapsed(true, for: archive) }
        _ = favorites.addEntry(home: home("web", ["url": "http://127.0.0.1:8766/cookie.html"]), title: "Notes")
        return SavedFavorites(favorites: favorites)
    }
}
