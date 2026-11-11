import AppKit
import SunsetPane
import SwiftUI

/// The icon a person gave a tab (`PaneIcon`), in the place and size of the tab's own picture: a symbol in the secondary colour, or an emoji as it is.
struct PaneIconView: View {
    let icon: PaneIcon

    /// Whether the system has a symbol of this name (a name typed by hand may be none: the tab then keeps its own picture).
    static func canShow(_ icon: PaneIcon) -> Bool {
        switch icon {
            case .symbol(let name): NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
            case .emoji: true
        }
    }

    var body: some View {
        switch icon {
            case .symbol(let name):
                Image(systemName: name).font(.system(size: 13)).foregroundStyle(.secondary).frame(width: 18)
            case .emoji(let emoji):
                Text(emoji).font(.system(size: 13)).frame(width: 18)
        }
    }
}
