import SwiftUI

/// A menu item's label: its title and its symbol, in the menu's own ink (n139: the owner chose a symbol for every item
/// that has one; n140: Share's was blue). A menu shows a label's title only unless told.
struct MenuItemLabel: View {
    let title: String
    let symbol: String?

    init(_ title: String, symbol: String?) {
        self.title = title
        self.symbol = symbol
    }

    var body: some View {
        if let symbol {
            Label(title, systemImage: symbol).labelStyle(.titleAndIcon)
        } else {
            Text(title)
        }
    }
}
