import SunsetPane
import SwiftUI

/// What a tab's menu offers, the same from its row and from any part of a split (a split's parts had none of it): the
/// layouts, the selection's actions, rename and icon, keeping, keeping the Mac awake, closing.
struct TabRowMenu: View {
    let tabs: TabsModel
    let item: Workspace.ItemID
    let animation: Animation?
    /// The page's own items (Reload, Copy Address, Site Settings); not in the address bar's menu, which has them first.
    var pageActions = true
    /// The part of a split the menu was opened on; nil from the row or the address bar, which mean the focused part.
    var pane: PaneID?

    var body: some View {
        // The menu's own ink for every symbol, never the accent (n140: they were blue).
        Group { items }.tint(.primary)
    }

    @ViewBuilder private var items: some View {
        TabLayoutMenu(tabs: tabs, row: .tab(item))
        SelectionMenu(tabs: tabs, row: .tab(item))
        // A split's row has no field of its own to rename in: the alert asks.
        if tabs.workspace.items.first(where: { $0.id == item })?.isSplit == true {
            Button {
                tabs.beginRename(item: item)
            } label: {
                MenuItemLabel("Rename Tab\u{2026}", symbol: "pencil")
            }
        } else {
            Button {
                tabs.renamingRow = .tab(item)
            } label: {
                MenuItemLabel("Rename", symbol: "pencil")
            }
        }
        Button {
            tabs.iconRow = .tab(item)
        } label: {
            MenuItemLabel("Change Icon\u{2026}", symbol: "face.smiling")
        }
        RowShareMenu(tabs: tabs, row: .tab(item))
        // What its panes' contents offer (a page's Reload, a document's other view).
        if pageActions {
            PaneActionsMenu(tabs: tabs, panes: tabs.workspace.items.first { $0.id == item }?.panes ?? []) {
                tabs.select(item: item)
            }
        }
        if tabs.canUnload(item: item) {
            Button {
                tabs.unload(item: item)
            } label: {
                MenuItemLabel("Unload", symbol: "minus.circle")
            }
        }
        Divider()
        TabKeepMenu(tabs: tabs, item: item, animation: animation)
        KeepAwakeMenu(tabs: tabs, item: item)
        Divider()
        closing
    }

    /// A split closes one part; the whole split only with Option held, as macOS keeps its less used items. A tab
    /// closes; Close Other Tabs with Option.
    @ViewBuilder private var closing: some View {
        let shown = tabs.workspace.items.first { $0.id == item }
        if let shown, shown.isSplit {
            let part = pane ?? shown.focused
            Button {
                tabs.requestClose(pane: part)
            } label: {
                MenuItemLabel("Close Pane", symbol: "xmark")
            }
            .modifierKeyAlternate(.option) {
                Button("Close All \(shown.panes.count) Panes") { tabs.close(item: item) }
            }
        } else {
            Button {
                tabs.close(item: item)
            } label: {
                MenuItemLabel("Close Tab", symbol: "xmark")
            }
            .modifierKeyAlternate(.option) {
                Button("Close Other Tabs") { tabs.closeOthers(than: item) }.disabled(tabs.workspace.count < 2)
            }
        }
    }
}
