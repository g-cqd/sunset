import AemiSDR
import SwiftUI

extension TabSidebar {
    /// Under the pin and the + bar: the rows that scroll there blur out as they fade, from full at the window's edge to none a little
    /// past the end (Sunset research/blur). Not clipped to the end's height: the fall reaches over the first row at rest; nor to the
    /// sidebar's width: the band reaches past both sides (the panes draw above it, the window's edge ends it).
    func listEndBlur(_ edge: BlurMask.Edge, over length: Double) -> some View {
        let solid = length * Design.Blur.listSolidShare
        return Color.clear
            .frame(height: length)
            .padding(.horizontal, -(margin + Design.Blur.listBleed))
            .blurUnder(
                edge,
                solid: solid,
                fade: length - solid + Design.Blur.listOverhang,
                radius: Design.Blur.listRadius
            )
    }
}
