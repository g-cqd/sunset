import SunsetMetrics
import SwiftUI

/// The thin line between two sections of the sidebar: under the Favorites (`FavoritesLine`) and under the Pinned grid (the
/// owner, 2026-11-17, roadmap 0038 E).
struct SectionSeparator: View {
    let layout: ShellSettings.Layout
    var visible = true

    var body: some View {
        Rectangle()
            .fill(.primary.opacity(layout.hairlineOpacity * Design.Line.stronger))
            .frame(height: max(layout.hairlineWidth, 0.5))
            .padding(.horizontal, layout.tabPaddingLeading)
            .opacity(visible ? 1 : 0)
            .frame(height: visible ? 6 : 8)
            .accessibilityHidden(true)
    }
}
