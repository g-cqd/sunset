import SunsetMetrics
import SunsetPane
import SwiftUI

/// The sidebar's list, and the list of the Space the window is sliding to (`SpaceSlide`; the owner's note n79). The Pinned
/// grid slides only to a Space of another profile (roadmap 0044 A).
extension TabSidebar {
    /// The parts of the list: the Pinned grid and the Favorites, which stay, and Today's tabs, which scroll (roadmap 0035 F).
    enum Part { case pinned, favorites, today }

    /// The rows: the Pinned grid, the Favorites, the tabs.
    var list: some View {
        VStack(spacing: layout.tabSpacing) {
            pinnedPart
            favoritesPart
            today
        }
    }

    /// The Pinned grid.
    var pinnedPart: some View {
        PinnedGrid(tabs: tabs, layout: layout)
            .padding(.horizontal, layout.tabSideInset)
            .frame(maxWidth: .infinity)
    }

    /// The Favorites.
    var favoritesPart: some View {
        FavoritesSection(tabs: tabs, settings: settings, layout: layout)
            .padding(.horizontal, layout.tabSideInset)
            .frame(maxWidth: .infinity)
    }

    /// Today's tabs.
    var today: some View {
        // Between two tabs, and at the top, a gap that takes a drop (roadmap 0038 F); after the last, `TodayEndDrop`.
        LazyVStack(spacing: 0) {
            ForEach(Array(tabs.workspace.items.enumerated()), id: \.element.id) { index, item in
                if isPreview {
                    if index > 0 { Color.clear.frame(height: layout.tabSpacing) }
                } else {
                    GapDrop(tabs: tabs, layout: layout, place: .today(at: index), between: index > 0)
                }
                row(item)
            }
            if tabs.dragTargets != nil, !isPreview { TodayEndDrop(tabs: tabs, layout: layout) }
        }
        .padding(.horizontal, layout.tabSideInset)
        .frame(maxWidth: .infinity)
    }

    /// The part of the list of the Space the window is sliding to, beside this one's (n79).
    @ViewBuilder func beside(_ part: Part) -> some View {
        if let beside = tabs.slide.beside, !beside.shares(part) {
            Group {
                switch part {
                    case .pinned: preview(beside.tabs).pinnedPart
                    case .favorites: preview(beside.tabs).favoritesPart
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
