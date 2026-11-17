import SunsetPane
import SwiftUI

/// What `View.hoverPreview(_:entry:)` does.
struct HoverPreview: ViewModifier {
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
