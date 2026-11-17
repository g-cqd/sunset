import SunsetPane
import SwiftUI

/// Where a tab can be kept, in its menu (the sidebar's row and the built-in bar's tab): pinned, a favourite, in a new
/// folder, in another Space.
struct TabKeepMenu: View {
    let tabs: TabsModel
    let item: Workspace.ItemID
    var animation: Animation?

    var body: some View {
        Button("Pin") { withAnimation(animation) { _ = tabs.pin(item: item) } }.disabled(!tabs.canPin)
        Button("Add to Favorites") { withAnimation(animation) { _ = tabs.keep(item: item) } }
        Button("New Folder with This Tab") { tabs.newFolder(with: item) }
        MoveToSpaceMenu(tabs: tabs, rows: [.tab(item)])
    }
}
