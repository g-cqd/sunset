import SunsetMetrics
import SunsetPane
import SwiftUI

/// The sidebar's list, and the list of the Space the window is sliding to (`SpaceSlide`; the owner's note n79).
extension TabSidebar {
    /// The parts of the list: the kept entries, which stay, and Today's tabs, which scroll (roadmap 0035 F).
    enum Part { case kept, today }

    /// The rows: the Pinned grid, the Favorites, the tabs.
    var list: some View {
        VStack(spacing: layout.tabSpacing) {
            kept
            today
        }
    }

    /// The Pinned grid and the Favorites.
    var kept: some View {
        VStack(spacing: layout.tabSpacing) {
            PinnedGrid(tabs: tabs, layout: layout)
            FavoritesSection(tabs: tabs, settings: settings, layout: layout)
        }
        .padding(.horizontal, layout.tabSideInset)
        .frame(maxWidth: .infinity)
    }

    /// Today's tabs.
    var today: some View {
        LazyVStack(spacing: layout.tabSpacing) {
            ForEach(tabs.workspace.items) { item in row(item) }
        }
        .padding(.horizontal, layout.tabSideInset)
        .frame(maxWidth: .infinity)
    }

    /// The part of the list of the Space the window is sliding to, beside this one's (n79).
    @ViewBuilder func beside(_ part: Part) -> some View {
        if let beside = tabs.slide.beside {
            Group {
                switch part {
                    case .kept: preview(beside.tabs).kept
                    case .today: preview(beside.tabs).today
                }
            }
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
