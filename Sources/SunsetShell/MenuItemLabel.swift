import SwiftUI

/// A menu item's label (n139, n140: Share was the only item with a symbol, and blue). Which items have a symbol is one
/// choice for every menu of a row: none, the page's actions (Duplicate, Copy, Share, Reload), or every item that has one.
/// Symbols are in the menu's own ink, never the accent.
struct MenuItemLabel: View {
    enum Kind {
        /// What is done to the page or its address.
        case action
        /// Everything else (rename, keep, close…).
        case other
    }

    let title: String
    let symbol: String?
    var kind = Kind.other

    init(_ title: String, symbol: String?, kind: Kind = .other) {
        self.title = title
        self.symbol = symbol
        self.kind = kind
    }

    var body: some View {
        // A menu shows a label's title only, unless told: then its symbol too.
        if let symbol, MenuIcons.style.shows(kind) {
            Label(title, systemImage: symbol).labelStyle(.titleAndIcon)
        } else if kind == .action, symbol == "square.and.arrow.up" {
            // A share link adds its own symbol to a plain title: a label shown title only keeps it out.
            Label(title, systemImage: "square.and.arrow.up").labelStyle(.titleOnly)
        } else {
            Text(title)
        }
    }
}
