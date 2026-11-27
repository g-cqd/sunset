import SunsetMetrics
import SwiftUI
import UniformTypeIdentifiers

/// The thin line between the Favorites and the tabs. A tab dropped on it is kept at the end of the Favorites. While a drag that it would take
/// is under way it is a place to drop, outlined and said ("Keep in Favorites"). With no Favorites yet it is drawn only while a tab is held
/// over it: an empty sidebar looks as before.
struct FavoritesLine: View {
    let tabs: TabsModel
    let layout: ShellSettings.Layout
    let visible: Bool
    @State private var targeted = false

    /// A drag under way would be kept in the Favorites: the line opens into a place to drop it, said in words.
    private var takesDrag: Bool {
        tabs.dragTargets?.favorites == true
    }

    var body: some View {
        Group {
            if takesDrag {
                Label("Keep in Favorites", systemImage: "star")
                    .font(Design.Text.detail)
                    .foregroundStyle(targeted ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    // As tall as a tab's row: a row's padding around a line of text.
                    .padding(.vertical, layout.tabPaddingVertical + Design.Space.s)
                    .dropTarget(shown: true, targeted: targeted, radius: layout.tabRadius)
                    .padding(.vertical, Design.Space.xs)
                    .transition(.opacity)
            } else {
                SectionSeparator(layout: layout, visible: visible, collapsed: !visible && !tabs.pinnedEntries.isEmpty)
            }
        }
        .contentShape(.rect)
        .onDrop(
            of: [.plainText, .utf8PlainText],
            delegate: TargetDrop(
                targeted: $targeted,
                allows: { tabs.canDropOnFavoritesLine },
                drop: { tabs.dropDraggedOnFavoritesLine() }
            )
        )
        .animation(layout.smooth, value: targeted)
        .animation(layout.smooth, value: takesDrag)
    }
}
