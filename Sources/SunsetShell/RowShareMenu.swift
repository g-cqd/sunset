import SunsetPane
import SwiftUI

/// Duplicate, Copy Address and Share in a row's menu (n136), for the row or for every selected row with it: tabs are
/// duplicated; the addresses are those of the pages in the tabs, in the kept entries, in every entry of a folder.
struct RowShareMenu: View {
    let tabs: TabsModel
    let row: RowTarget

    var body: some View {
        let rows = tabs.rows(actingOn: row)
        let tabCount = rows.filter { if case .tab = $0 { true } else { false } }.count
        let addresses = tabs.addresses(of: rows)
        if tabCount > 0 {
            Button {
                tabs.duplicate(rows)
            } label: {
                MenuItemLabel(
                    tabCount == 1 ? "Duplicate" : "Duplicate \(tabCount) Tabs",
                    symbol: "plus.square.on.square",
                    kind: .action
                )
            }
        }
        // One open page has its own Copy Address among its actions.
        if !addresses.isEmpty, rows.count > 1 || !showsPageActions {
            Button {
                Clipboard.copyAndSay(
                    addresses.map(\.absoluteString).joined(separator: "\n"),
                    isLink: addresses.count == 1,
                    what: addresses.count == 1 ? "Copied the address" : "Copied \(addresses.count) addresses"
                )
            } label: {
                MenuItemLabel(
                    addresses.count == 1 ? "Copy Address" : "Copy \(addresses.count) Addresses",
                    symbol: "link",
                    kind: .action
                )
            }
        }
        if !addresses.isEmpty {
            ShareLink(items: addresses) {
                MenuItemLabel(
                    addresses.count == 1 ? "Share\u{2026}" : "Share \(addresses.count) Pages\u{2026}",
                    symbol: "square.and.arrow.up",
                    kind: .action
                )
            }
            // A share link takes the accent (n140: blue in the menu): the menu's own ink, as every item's.
            .tint(.primary)
        }
    }

    /// Whether the row's menu lists its page's own actions: a tab, an open entry.
    private var showsPageActions: Bool {
        switch row {
            case .tab: true
            case .node(let id): tabs.keeper(of: id).favorites.entry(id)?.isOpen == true
        }
    }
}
