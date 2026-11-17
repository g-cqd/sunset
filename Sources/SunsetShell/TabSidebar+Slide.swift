import SunsetMetrics
import SunsetPane
import SwiftUI

/// The sidebar's list, and the list of the Space the window is sliding to (`SpaceSlide`; the owner's note n79).
extension TabSidebar {
    /// The rows: the Pinned grid, the Favorites, the tabs.
    var list: some View {
        LazyVStack(spacing: layout.tabSpacing) {
            PinnedGrid(tabs: tabs, layout: layout)
            FavoritesSection(tabs: tabs, settings: settings, layout: layout)
            ForEach(tabs.workspace.items) { item in row(item) }
        }
        .padding(.horizontal, layout.tabSideInset)
        .frame(maxWidth: .infinity)
    }

    /// The list of the Space the window is sliding to, beside this one's (n79).
    @ViewBuilder var beside: some View {
        if let beside = tabs.slide.beside {
            preview(beside.tabs)
                .offset(x: tabs.slide.shift + (beside.isNext ? tabs.slide.width : -tabs.slide.width))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// This sidebar's list for another window's model: the rows alone.
    private func preview(_ model: TabsModel) -> TabSidebar {
        var other = self
        other.tabs = model
        other.isPreview = true
        return other
    }
}
