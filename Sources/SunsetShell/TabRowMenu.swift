import SunsetPane
import SwiftUI

/// What a tab's menu offers, the same from its row and from any part of a split (the owner, 2026-11-17: a split's parts had
/// none of it): the layouts, the selection's actions, rename and icon, keeping, keeping the Mac awake, closing.
struct TabRowMenu: View {
    let tabs: TabsModel
    let item: Workspace.ItemID
    let animation: Animation?

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
        Divider()
        TabKeepMenu(tabs: tabs, item: item, animation: animation)
        KeepAwakeMenu(tabs: tabs, item: item)
        Divider()
        Button("Close Tab") { tabs.close(item: item) }
        Button("Close Other Tabs") { tabs.closeOthers(than: item) }
            .disabled(tabs.workspace.count < 2)
    }
}
