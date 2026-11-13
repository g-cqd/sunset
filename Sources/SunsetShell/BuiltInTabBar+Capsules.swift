import AemiSDR
import SunsetPane
import SwiftUI

extension BuiltInTabBar {
    /// The Favorites in the row of capsules: a circle each (a folder's too); the tabs' leading blur sets them off.
    func pinned(_ items: [Favorites.BarItem]) -> some View {
        HStack(spacing: Design.Space.s) {
            ForEach(items, id: \.self) { item in
                barItem(item).frame(width: Design.TabCapsules.height)
            }
        }
        .environment(\.tabIconOnly, true)
    }

    /// The tabs fade out over each end's solid part and a little before, where tabs lie beyond it, so the blurred tab has no edge
    /// where the row ends.
    var endFade: some View {
        HStack(spacing: 0) {
            ramp(shown: beyond.leading, towards: .leading)
            Color.black
            ramp(shown: beyond.trailing, towards: .trailing)
        }
    }

    private func ramp(shown: Bool, towards edge: HorizontalEdge) -> some View {
        LinearGradient(
            colors: shown ? [.black, .clear] : [.black, .black],
            startPoint: edge == .trailing ? .leading : .trailing,
            endPoint: edge == .trailing ? .trailing : .leading
        )
        .frame(width: Design.Blur.tabEndSolid + Design.Space.l)
    }

    /// Over the tabs' end: full blur at the end, none `tabEndFade` before it; the bar behind is one colour, so only the tabs
    /// passing under show it.
    func endBlur(_ edge: BlurMask.Edge) -> some View {
        BlurBackdropView(
            Design.Blur.under(
                edge,
                solid: Design.Blur.tabEndSolid,
                fade: Design.Blur.tabEndFade,
                radius: Design.Blur.tabEndRadius
            )
        )
        .frame(width: Design.Blur.tabEndSolid + Design.Blur.tabEndFade)
        .allowsHitTesting(false)
    }
}
