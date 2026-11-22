import SunsetMetrics
import SunsetPane
import SwiftUI

/// The sidebar's list, and the list of the Space the window is sliding to (`SpaceSlide`; the owner's note n79). The Pinned
/// grid slides only to a Space of another profile (roadmap 0044 A).
extension TabSidebar {
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
                    // The rows beside it make room instead of a line (n79); the gap stays where it is, so that the
                    // rows moving do not take the drop from under the pointer (n84).
                    GapDrop(tabs: tabs, layout: layout, place: .today(at: index), between: index > 0, line: false) {
                        targeted in
                        if targeted { gapRoom = index } else if gapRoom == index { gapRoom = nil }
                    }
                }
                row(item)
            }
            if tabs.dragTargets != nil, !isPreview { TodayEndDrop(tabs: tabs, layout: layout) }
        }
        .padding(.horizontal, layout.tabSideInset)
        .frame(maxWidth: .infinity)
    }

    /// The list of the Space the window is sliding to, beside this one's (n79): a column of its own from the top, so that
    /// its tabs follow its own Pinned grid and Favorites, where they will be once the slide has ended (roadmap 0045 E). A
    /// part both Spaces show keeps its place, empty: this list draws it, still.
    @ViewBuilder var besideColumn: some View {
        if let beside = tabs.slide.beside {
            let other = preview(beside.tabs)
            VStack(spacing: layout.tabSpacing) {
                ForEach(beside.column, id: \.self) { part in
                    switch part {
                        case .kept(.pinned): Color.clear.frame(height: keptHeights.pinned)
                        case .kept(.favorites): Color.clear.frame(height: keptHeights.favorites)
                        case .own(.pinned): other.pinnedPart
                        case .own(.favorites): other.favoritesPart
                        case .own(.today), .kept(.today): other.today
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            // Faded above the app's bar as this list's tabs are.
            .mask { fade(scrolled: 0) }
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
