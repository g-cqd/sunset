import SunsetPane
import SwiftUI

/// Where a tab can be kept, in its menu (the sidebar's row and the built-in bar's tab): pinned, a favourite, in a new
/// folder, in another Space.
struct TabKeepMenu: View {
    let tabs: TabsModel
    let item: Workspace.ItemID
    var animation: Animation?

    var body: some View {
        Button {
            withAnimation(animation) { _ = tabs.pin(item: item) }
        } label: {
            MenuItemLabel("Pin", symbol: "pin")
        }
        .disabled(!tabs.canPin)
        Button {
            withAnimation(animation) { _ = tabs.keep(item: item) }
        } label: {
            MenuItemLabel("Add to Favorites", symbol: "star")
        }
        Button {
            tabs.newFolder(with: item)
        } label: {
            MenuItemLabel("New Folder with This Tab", symbol: "folder.badge.plus")
        }
        MoveToSpaceMenu(tabs: tabs, rows: [.tab(item)])
    }
}
