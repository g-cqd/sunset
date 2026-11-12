import AppKit
import SunsetPane
import SwiftUI

/// The icon a person gave a tab, an entry or a folder (`PaneIcon`), in the place and size of the tab's own picture: a symbol in its colour (the secondary
/// colour when it has none), or an emoji as it is.
struct PaneIconView: View {
    let icon: PaneIcon

    /// Whether the system has a symbol of this name (a name typed by hand may be none: the tab then keeps its own picture).
    static func canShow(_ icon: PaneIcon) -> Bool {
        switch icon {
            case .symbol(let name, _): NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
            case .emoji: true
        }
    }

    var body: some View {
        switch icon {
            case .symbol(let name, let color):
                Image(systemName: name)
                    .font(.system(size: Design.Symbol.row))
                    .foregroundStyle(color.map { AnyShapeStyle(Color($0)) } ?? AnyShapeStyle(.secondary))
                    .frame(width: Design.Size.glyphFrame)
            case .emoji(let emoji):
                Text(emoji).font(.system(size: Design.Symbol.row)).frame(width: Design.Size.glyphFrame)
        }
    }
}
