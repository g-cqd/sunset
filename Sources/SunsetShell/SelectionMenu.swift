import SunsetPane
import SwiftUI

/// What the context menu of a row offers for the rows selected with it (R3 step d), above the row's own items.
struct SelectionMenu: View {
    let tabs: TabsModel
    let row: RowTarget

    var body: some View {
        let rows = tabs.rows(actingOn: row)
        if rows.count > 1 {
            Button("New Folder with \(rows.count) Items") { tabs.group(rows) }
            let pinnable = rows.filter { tabs.canPin($0) }.count
            if pinnable > 0 { Button("Pin \(pinnable)") { tabs.pin(rows) } }
            if rows.contains(where: { if case .tab = $0 { true } else { false } }) {
                Button("Add \(count(rows, tabs: true)) to Favorites") { tabs.addToFavorites(rows) }
            }
            if count(rows, tabs: false) > 0 {
                Button("Remove \(count(rows, tabs: false)) from Favorites") { tabs.removeFromFavorites(rows) }
                Button("Delete \(nodes(rows)) Items") { tabs.delete(rows) }
            }
            if count(rows, tabs: true) > 0 { MoveToSpaceMenu(tabs: tabs, rows: rows) }
            Divider()
        }
    }

    /// The tabs among the rows, or the entries.
    private func count(_ rows: [RowTarget], tabs wantTabs: Bool) -> Int {
        rows.filter { row in
            switch row {
                case .tab: wantTabs
                case .node(let id): !wantTabs && tabs.favorites.favorites.entry(id) != nil
            }
        }
        .count
    }

    private func nodes(_ rows: [RowTarget]) -> Int { rows.filter { if case .node = $0 { true } else { false } }.count }
}
