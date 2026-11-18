import SunsetPane
import SwiftUI

/// What `View.hoverPreview(_:entry:)` and `View.hoverPreview(_:folder:)` do: the row under the pointer, and where it is, for
/// the hover card.
struct HoverPreview: ViewModifier {
    /// What the row is: an open kept entry (its tab's card), or a folder (the list of its tabs, n77).
    enum Target {
        case entry(Favorites.NodeID)
        case folder(Favorites.NodeID)
    }

    let tabs: TabsModel
    let target: Target
    @State private var frame: CGRect?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame = $0 }
            .onHover { inside in
                switch target {
                    case .entry(let entry): hover(entry: entry, inside: inside)
                    case .folder(let folder): hover(folder: folder, inside: inside)
                }
            }
    }

    private func hover(entry: Favorites.NodeID, inside: Bool) {
        let id = tabs.hoverID(entry: entry)
        if inside, let id {
            tabs.hoveredItem = id
            tabs.hoveredRowFrame = frame
        } else if let id, tabs.hoveredItem == id {
            tabs.hoveredItem = nil
        }
    }

    private func hover(folder: Favorites.NodeID, inside: Bool) {
        if inside {
            tabs.hoveredFolder = folder
            tabs.hoveredRowFrame = frame
        } else if tabs.hoveredFolder == folder {
            tabs.hoveredFolder = nil
        }
    }
}
