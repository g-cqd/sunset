import SunsetMetrics
import SunsetPane
package import SwiftUI

/// The tab bar of our own, for `tabs.mode: internal`: one window, many terminals, drawn in the sidebar's language (owner, 2026-11-12): each
/// tab a sidebar row, the bar itself with no material of its own (the window's backdrop shows, as behind the sidebar), the tabs sharing
/// its width. The kept entries that are open come first, then a thin line and the window's tabs (R3). Tabs are selected by a click, closed
/// by their button (in the icon's place under the pointer) or the menu, and reordered by dragging; an entry's button unloads it.
package struct BuiltInTabBar: View {
    let tabs: TabsModel
    let settings: ShellSettings.Bar
    @Environment(\.surfaceStyle) var surface
    @State var frames: [UUID: CGRect] = [:]

    package init(tabs: TabsModel, settings: ShellSettings.Bar) {
        self.tabs = tabs
        self.settings = settings
    }

    /// The narrowest and the widest a tab is: the tabs share the bar between these.
    static let tabWidths = 120.0 ... 240.0

    package var body: some View {
        let items = tabs.favorites.favorites.barItems(selected: tabs.workspace.selectedEntry)
        let count = items.count + tabs.workspace.items.count
        HStack(spacing: Design.Space.xs) {
            GeometryReader { proxy in
                let width = Self.width(for: count, in: proxy.size.width, gap: surface.layout.tabSpacing)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: surface.layout.tabSpacing) {
                        ForEach(items, id: \.self) { item in barItem(item).frame(width: width) }
                        if !items.isEmpty { separator }
                        ForEach(tabs.workspace.items) { item in row(item).frame(width: width) }
                    }
                    .frame(maxHeight: .infinity)
                }
                .gesture(WindowDragGesture())
            }
            SidebarIconButton(symbol: "plus", help: "New Tab") { tabs.newTab() }
                .environment(\.sidebarButtonMetrics, BarButton.metrics(surface))
        }
        .padding(.horizontal, surface.layout.tabSideInset + Design.Space.xs)
        .padding(.vertical, Design.Space.xs)
        .frame(height: rowHeight + 2 * Design.Space.xs)
    }

    /// As tall as a sidebar row with the lines the bar shows.
    private var rowHeight: Double {
        settings.showDirectory ? Design.Size.tabRow + Design.Space.xs : Design.Size.tabRow
    }

    /// Each tab's width: the bar shared equally, between `tabWidths`.
    static func width(for count: Int, in available: Double, gap: Double) -> Double {
        guard count > 0 else { return tabWidths.upperBound }
        let share = (available - gap * Double(count - 1)) / Double(count)
        return min(max(share, tabWidths.lowerBound), tabWidths.upperBound)
    }

    private var separator: some View {
        Rectangle()
            .fill(.primary.opacity(surface.layout.hairlineOpacity * Design.Line.stronger))
            .frame(width: max(surface.layout.hairlineWidth, 1), height: surface.layout.closeButtonSize)
            .padding(.horizontal, Design.Space.xs)
    }
}
