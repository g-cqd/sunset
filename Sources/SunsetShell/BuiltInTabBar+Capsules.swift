import AemiSDR
import SunsetPane
import SwiftUI

extension BuiltInTabBar {
    /// The Favorites in the row of capsules: a circle each (a folder's too), then the line that sets them off from the tabs.
    func pinned(_ items: [Favorites.BarItem]) -> some View {
        HStack(spacing: Design.Space.s) {
            ForEach(items, id: \.self) { item in
                barItem(item).frame(width: Design.TabCapsules.height)
            }
            separator
        }
        .environment(\.tabIconOnly, true)
    }

    /// The tabs fade out over the blur's solid part and a little before, so the blurred tab has no edge where the row ends.
    var trailingFade: some View {
        HStack(spacing: 0) {
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: Design.Blur.tabEndSolid + Design.Space.l)
        }
    }

    /// Over the tabs' trailing end: full blur at the end, none `tabEndFade` before it; the bar behind is one colour, so only the
    /// tabs passing under show it.
    var trailingBlur: some View {
        BlurBackdropView(
            Design.Blur.under(
                .trailing,
                solid: Design.Blur.tabEndSolid,
                fade: Design.Blur.tabEndFade,
                radius: Design.Blur.listRadius
            )
        )
        .frame(width: Design.Blur.tabEndSolid + Design.Blur.tabEndFade)
        .allowsHitTesting(false)
    }
}
