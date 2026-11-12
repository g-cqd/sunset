import AemiSDR
import SwiftUI

extension TabSidebar {
    /// Under the pin and the + bar: the rows that scroll there blur out as they fade, from full at the window's edge to none a little
    /// past the end (Sunset research/blur). Not clipped to the end's height: the fall reaches over the first row at rest.
    func listEndBlur(_ edge: BlurMask.Edge, over length: Double) -> some View {
        let solid = length * Design.Blur.listSolidShare
        return Color.clear
            .frame(height: length)
            .blurUnder(
                edge,
                solid: solid,
                fade: length - solid + Design.Blur.listOverhang,
                radius: Design.Blur.listRadius
            )
    }
}
