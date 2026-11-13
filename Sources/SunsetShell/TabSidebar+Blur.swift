import AemiSDR
import SwiftUI

extension TabSidebar {
    /// Under the pin and the + bar: the rows that scroll there blur out as they fade, from full at the window's edge to none a little
    /// past the end (Sunset research/blur). Not clipped to the end's height: the fall reaches over the first row at rest; nor to the
    /// sidebar's width: the band reaches past both sides (the panes draw above it, the window's edge ends it).
    /// `reach` past the end too: the docked sidebar sits a margin below the window's top, and its band goes on to the edge
    /// (owner, 2026-11-13, t231).
    func listEndBlur(_ edge: BlurMask.Edge, over length: Double, reach: Double = 0) -> some View {
        let solid = length * Design.Blur.listSolidShare
        return Color.clear
            .frame(height: length)
            .padding(edge == .top ? .top : .bottom, -reach)
            .padding(.horizontal, -(margin + Design.Blur.listBleed))
            .blurUnder(
                edge,
                solid: solid + reach,
                fade: length - solid + Design.Blur.listOverhang,
                radius: Design.Blur.listRadius
            )
            .allowsHitTesting(false)
    }
}
