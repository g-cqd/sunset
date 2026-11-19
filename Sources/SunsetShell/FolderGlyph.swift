import SunsetPane
import SwiftUI

/// A folder's glyph, the same in its row and in its card under the pointer (the owner's note n56: the card showed a plain
/// folder): its own icon when it has one the system can draw, else a folder, filled while open.
struct FolderGlyph: View {
    let folder: Favorites.Folder
    let open: Bool

    /// The folder's own icon, when it can be drawn.
    var custom: PaneIcon? {
        folder.icon.flatMap { PaneIconView.canShow($0) ? $0 : nil }
    }

    /// The symbol shown when it has none.
    var symbol: String {
        open ? "folder.fill" : "folder"
    }

    var body: some View {
        if let custom {
            PaneIconView(icon: custom).opacity(open ? 1 : Design.Fill.collapsedIcon)
        } else {
            Image(systemName: symbol)
                .font(.system(size: Design.Symbol.row))
                .foregroundStyle(.secondary)
                .frame(width: Design.Size.glyphFrame)
        }
    }
}
