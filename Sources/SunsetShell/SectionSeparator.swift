import SunsetMetrics
import SwiftUI

/// The thin line between two sections of the sidebar: under the Favorites (`FavoritesLine`) and under the Pinned grid (the
/// owner, 2026-11-17, roadmap 0038 E).
struct SectionSeparator: View {
    let layout: ShellSettings.Layout
    var visible = true
    @Environment(\.sectionSeparators) private var drawn

    /// The room it takes: the line in the middle.
    static let room = 6.0
    /// The room it takes hidden (the Favorites' line with no Favorites, as before).
    static let hiddenRoom = 8.0

    var body: some View {
        Rectangle()
            .fill(.primary.opacity(layout.hairlineOpacity * Design.Line.stronger))
            .frame(height: max(layout.hairlineWidth, 0.5))
            .padding(.horizontal, layout.tabPaddingLeading)
            // Off (`sidebar.separators`), the line goes and its room stays.
            .opacity(visible && drawn ? 1 : 0)
            .frame(height: visible ? Self.room : Self.hiddenRoom)
            .accessibilityHidden(true)
    }
}
