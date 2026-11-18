import SunsetPane
package import SwiftUI

/// The menu of what a window shows, its tab's or its kept entry's: what the address bar's menu adds after the page's own
/// items (roadmap 0047 F).
package struct ShownTabMenu: View {
    let tabs: TabsModel

    package init(tabs: TabsModel) { self.tabs = tabs }

    package var body: some View {
        if let entry = tabs.shownEntry {
            KeptEntryMenu(tabs: tabs, entry: entry, editsInPlace: false)
        } else if let item = tabs.workspace.selectedID {
            TabRowMenu(tabs: tabs, item: item, animation: nil, pageActions: false)
        }
    }
}
