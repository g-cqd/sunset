import AemiSDR
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
    /// Back and forward of the selected page, after the window's buttons (t223); nil while a terminal is selected.
    let navigation: AnyView?
    /// The selected page's address field, in its tab's place (t223): the selected tab is the field.
    let address: AnyView?
    /// The row of capsules (`Design.TabCapsules`): set while the bar holds the address, whatever is selected, so that the bar does not
    /// change shape from a page to a terminal.
    let capsules: Bool
    @State var frames: [UUID: CGRect] = [:]
    /// Tabs lie beyond the row's leading (trailing) end: its blur shows there.
    @State var beyond = (leading: false, trailing: false)

    package init(
        tabs: TabsModel,
        settings: ShellSettings.Bar,
        navigation: AnyView? = nil,
        address: AnyView? = nil,
        capsules: Bool = false
    ) {
        self.tabs = tabs
        self.settings = settings
        self.navigation = navigation
        self.address = address
        self.capsules = capsules
    }

    private var pinnedItems: [Favorites.BarItem] {
        tabs.favorites.favorites.pinnedItems(selected: tabs.workspace.selectedEntry)
    }

    /// The narrowest and the widest a tab is: the tabs share the bar between these.
    static let tabWidths = 120.0 ... 240.0

    package var body: some View {
        let items = tabs.favorites.favorites.barItems(selected: tabs.workspace.selectedEntry)
        let count = items.count + tabs.workspace.items.count
        HStack(spacing: capsules ? Design.Space.m : Design.Space.xs) {
            if let navigation { navigation.transition(.opacity) }
            // Pinned: the Favorites as circles before the tabs, outside their scroll (owner, 2026-11-13).
            if capsules, !pinnedItems.isEmpty { pinned(pinnedItems) }
            GeometryReader { proxy in
                let width = Self.width(
                    for: capsules ? tabs.workspace.items.count : count,
                    in: proxy.size.width,
                    gap: capsules ? Design.TabCapsules.tabGap : surface.layout.tabSpacing
                )
                ScrollViewReader { reader in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: capsules ? Design.TabCapsules.tabGap : surface.layout.tabSpacing) {
                            if !capsules {
                                ForEach(items, id: \.self) { item in barItem(item).frame(width: width) }
                                if !items.isEmpty { separator }
                            }
                            ForEach(tabs.workspace.items) { item in
                                if let address, tabs.isSelected(item.id) {
                                    address.frame(width: Self.fieldWidth(tab: width)).id(item.id)
                                } else {
                                    row(item).frame(width: width).id(item.id)
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    // The selected tab is scrolled into view (a click, Show Next Tab, an accessibility press).
                    .onChange(of: tabs.workspace.selectedID, initial: true) { _, id in
                        guard let id else { return }
                        withAnimation(surface.layout.smooth) { reader.scrollTo(id) }
                    }
                }
                .gesture(WindowDragGesture())
                // The tabs that scroll under the + blur out towards it (owner, 2026-11-13).
                .onScrollGeometryChange(for: Bool.self, of: { $0.contentOffset.x > 0.5 }) { _, now in
                    beyond.leading = now
                }
                .onScrollGeometryChange(
                    for: Bool.self,
                    of: { $0.contentOffset.x + $0.containerSize.width < $0.contentSize.width - 0.5 }
                ) { _, now in beyond.trailing = now }
                // The tabs that scroll past either end blur and fade out there (owner, 2026-11-13).
                .overlay(alignment: .leading) { if capsules, beyond.leading { endBlur(.leading) } }
                .overlay(alignment: .trailing) { if capsules, beyond.trailing { endBlur(.trailing) } }
                .mask { if capsules { endFade } else { Color.black } }
                .animation(surface.layout.smooth, value: beyond.leading)
                .animation(surface.layout.smooth, value: beyond.trailing)
            }
            if capsules {
                TabCapsuleButton(symbol: "plus", help: "New Tab") { tabs.newTab() }
            } else {
                SidebarIconButton(symbol: "plus", help: "New Tab") { tabs.newTab() }
                    .environment(\.sidebarButtonMetrics, BarButton.metrics(surface))
            }
        }
        .padding(.horizontal, capsules ? Design.TabCapsules.inset : surface.layout.tabSideInset + Design.Space.xs)
        .padding(.vertical, capsules ? Design.TabCapsules.inset : Design.Space.xs)
        .frame(height: capsules ? Design.TabCapsules.bar : rowHeight + 2 * Design.Space.xs)
        .environment(\.tabCapsules, capsules)
        .animation(.easeOut(duration: 0.18), value: navigation == nil)
    }

    /// As tall as a sidebar row with the lines the bar shows.
    private var rowHeight: Double {
        settings.showDirectory ? Design.Size.tabRow + Design.Space.xs : Design.Size.tabRow
    }

    /// The selected page's field: twice a tab, as wide as the command bar at most.
    static func fieldWidth(tab: Double) -> Double { min(2 * tab, Design.Width.commandBar) }

    /// Each tab's width: the bar shared equally, between `tabWidths`.
    static func width(for count: Int, in available: Double, gap: Double) -> Double {
        guard count > 0 else { return tabWidths.upperBound }
        let share = (available - gap * Double(count - 1)) / Double(count)
        return min(max(share, tabWidths.lowerBound), tabWidths.upperBound)
    }

    var separator: some View {
        Rectangle()
            .fill(.primary.opacity(surface.layout.hairlineOpacity * Design.Line.stronger))
            .frame(width: max(surface.layout.hairlineWidth, 1), height: surface.layout.closeButtonSize)
            .padding(.horizontal, Design.Space.xs)
    }
}
