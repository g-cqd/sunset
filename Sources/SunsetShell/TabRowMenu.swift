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
        TabLayoutMenu(tabs: tabs, row: .tab(item))
        SelectionMenu(tabs: tabs, row: .tab(item))
        // A split's row has no field of its own to rename in: the alert asks.
        if tabs.workspace.items.first(where: { $0.id == item })?.isSplit == true {
            Button("Rename Tab\u{2026}") { tabs.beginRename(item: item) }
        } else {
            Button("Rename") { tabs.renamingRow = .tab(item) }
        }
        Button("Change Icon\u{2026}") { tabs.iconRow = .tab(item) }
        // What its panes' contents offer (a page's Reload, a document's other view).
        if pageActions {
            PaneActionsMenu(tabs: tabs, panes: tabs.workspace.items.first { $0.id == item }?.panes ?? []) {
                tabs.select(item: item)
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
            Button("Close Pane") { tabs.requestClose(pane: part) }
                .modifierKeyAlternate(.option) {
                    Button("Close All \(shown.panes.count) Panes") { tabs.close(item: item) }
                }
        } else {
            Button("Close Tab") { tabs.close(item: item) }
                .modifierKeyAlternate(.option) {
                    Button("Close Other Tabs") { tabs.closeOthers(than: item) }.disabled(tabs.workspace.count < 2)
                }
        }
    }
}
