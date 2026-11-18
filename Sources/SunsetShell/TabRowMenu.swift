import SunsetPane
import SwiftUI

/// What a tab's menu offers, the same from its row and from any part of a split (the owner, 2026-11-17: a split's parts had
/// none of it): the layouts, the selection's actions, rename and icon, keeping, keeping the Mac awake, closing.
struct TabRowMenu: View {
    let tabs: TabsModel
    let item: Workspace.ItemID
    let animation: Animation?
    /// The page's own items (Reload, Copy Address, Site Settings); not in the address bar's menu, which has them first.
    var pageActions = true

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
        // The page's own (roadmap 0047 G): its site's settings open beside its address, the tab shown.
        let actions =
            tabs.workspace.items.first { $0.id == item }.flatMap { tabs.content($0.focused) }?.menuActions ?? []
        if pageActions, !actions.isEmpty {
            Divider()
            ForEach(actions.indices, id: \.self) { index in
                Button(actions[index].title) {
                    tabs.select(item: item)
                    actions[index].run()
                }
            }
        }
        Button("Tab Settings\u{2026}") { tabs.showSingle(.settings(topic: "tabs.placement")) }
        Divider()
        TabKeepMenu(tabs: tabs, item: item, animation: animation)
        KeepAwakeMenu(tabs: tabs, item: item)
        Divider()
        Button("Close Tab") { tabs.close(item: item) }
        Button("Close Other Tabs") { tabs.closeOthers(than: item) }
            .disabled(tabs.workspace.count < 2)
    }
}
