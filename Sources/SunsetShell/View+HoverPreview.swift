import SunsetPane
import SwiftUI

extension View {
    /// The row of a kept entry under the pointer is the hover card's while the entry is open (the owner, 2026-11-17: "no
    /// preview on loaded favorites tabs or pinned tabs"), as a tab's row is.
    func hoverPreview(_ tabs: TabsModel, entry: Favorites.NodeID) -> some View {
        modifier(HoverPreview(tabs: tabs, entry: entry))
    }
}

private struct HoverPreview: ViewModifier {
    let tabs: TabsModel
    let entry: Favorites.NodeID
    @State private var frame: CGRect?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame = $0 }
            .onHover { inside in
                let id = tabs.hoverID(entry: entry)
                if inside, let id {
                    tabs.hoveredItem = id
                    tabs.hoveredRowFrame = frame
                } else if let id, tabs.hoveredItem == id {
                    tabs.hoveredItem = nil
                }
            }
    }
}
