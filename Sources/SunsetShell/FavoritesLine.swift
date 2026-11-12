import SunsetMetrics
import SwiftUI
import UniformTypeIdentifiers

/// The thin line between the Favorites and the tabs (R3). A tab dropped on it is kept at the end of the Favorites. With no Favorites yet it is drawn only
/// while a tab is held over it: an empty sidebar looks as before.
struct FavoritesLine: View {
    let tabs: TabsModel
    let layout: ShellSettings.Layout
    let visible: Bool
    @State private var targeted = false

    var body: some View {
        Rectangle()
            .fill(targeted ? Color(nsColor: .controlAccentColor) : .primary.opacity(layout.hairlineOpacity * 1.5))
            .frame(height: targeted ? 2 : max(layout.hairlineWidth, 0.5))
            .padding(.horizontal, layout.tabPaddingLeading)
            .opacity(visible || targeted ? 1 : 0)
            .frame(height: visible ? 6 : 8)
            .contentShape(.rect)
            .onDrop(of: [.plainText, .utf8PlainText], delegate: LineDrop(tabs: tabs, targeted: $targeted))
            .animation(layout.smooth, value: targeted)
    }

    private struct LineDrop: DropDelegate {
        let tabs: TabsModel
        @Binding var targeted: Bool

        func validateDrop(info: DropInfo) -> Bool { tabs.canDropOnFavoritesLine }
        func dropEntered(info: DropInfo) { targeted = tabs.canDropOnFavoritesLine }
        func dropExited(info: DropInfo) { targeted = false }
        func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: targeted ? .move : .cancel) }
        func performDrop(info: DropInfo) -> Bool {
            targeted = false
            return tabs.dropDraggedOnFavoritesLine()
        }
    }
}
