import SunsetConfig
import SunsetHost
import SunsetPane
import SwiftUI

/// The sidebar: the tabs of the window, listed vertically (the same `Workspace` the built-in bar shows), and nothing else. It has no background of its own
/// (the window's own colour or material shows through, with the window's settings) and is not a system list: the rows are `SidebarRow`s in a scroll view whose
/// content starts below the traffic lights and scrolls beneath them, fading out there. A click selects a tab, a drag reorders them.
struct TabSidebar: View {
    let tabs: TabsModel
    let settings: Configuration
    /// The floating panel: its traffic lights are a little further from the corner.
    var floating = false
    /// The floating panel's corner radius: the pin button's corner towards the panel's is concentric with it (same gap to both edges).
    var panelRadius: Double?

    private var margin: Double { settings.sidebar.padding }
    /// The metrics the tabs draw with: the docked ones, or the floating panel's own.
    private var layout: Configuration.Layout { floating ? settings.layout.floatingTabs : settings.layout }
    private var header: SidebarHeader { SidebarHeader(layout: layout, margin: margin, floating: floating) }
    private var topInset: Double { header.height }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: layout.tabSpacing) {
                ForEach(tabs.workspace.items) { item in row(item) }
            }
            .padding(.horizontal, layout.tabSideInset)
        }
        .scrollIndicators(.never)
        .contentMargins(.top, topInset, for: .scrollContent)
        .contentMargins(.bottom, margin, for: .scrollContent)
        .mask { fade }
        .overlay(alignment: settings.sidebar.side == .left ? .topTrailing : .topLeading) { pinButton }
    }

    /// Content that scrolls up past the traffic lights fades out over the height of the strip they sit in; rows at rest start below it, untouched.
    private var fade: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: max(topInset - 4, 0))
            Color.black
        }
    }

    @ViewBuilder private func rowContent(_ item: Workspace.Item) -> some View {
        if item.isSplit {
            SidebarGroupRow(item: item, tabs: tabs, selected: item.id == tabs.workspace.selectedID, layout: layout)
        } else {
            SidebarRow(
                model: tabs.models[item.focused],
                selected: item.id == tabs.workspace.selectedID,
                showIcon: settings.tabs.bar.showIcon,
                showTitle: settings.tabs.bar.showTitle,
                showDirectory: settings.tabs.bar.showDirectory,
                showProgress: settings.tabs.bar.showProgress,
                layout: layout,
                close: { tabs.close(item: item.id) }
            )
        }
    }

    private func row(_ item: Workspace.Item) -> some View {
        rowContent(item)
            .onTapGesture { tabs.select(item: item.id) }
            .onDrag { tabs.itemProvider(for: .item(item.id)) }
            .dropDestination(for: String.self) { items, _ in
                guard let text = items.first, case .item(let id)? = PaneDragPayload(text: text),
                    let index = tabs.workspace.items.firstIndex(where: { $0.id == item.id })
                else { return false }
                tabs.move(item: id, to: index)
                return true
            }
            .contextMenu {
                Button("Close Tab") { tabs.close(item: item.id) }
                Button("Close Other Tabs") { tabs.closeOthers(than: item.id) }
                    .disabled(tabs.workspace.count < 2)
            }
    }

    /// Pins the sidebar beside the terminal (`sidebar.autoHide` off) or lets it hide and float: the sidebar symbol, filled while the sidebar is open
    /// (pinned) and outlined while it only appears on hover. Its container is a rounded square the size of the hit box, highlighted under the pointer like a
    /// tab, with its trailing edge on the tabs' trailing edge and its middle on the traffic lights'.
    private var pinButton: some View {
        PinButton(
            pinned: !settings.sidebar.autoHide,
            layout: layout,
            radius: pinRadius,
            size: panelRadius == nil ? CGSize(width: header.dockedButtonSize, height: header.dockedButtonHeight) : nil
        ) {
            AppConfiguration.shared.update { $0.sidebar.autoHide.toggle() }
        }
        .padding(
            settings.sidebar.side == .left ? .trailing : .leading,
            pinGap + (panelRadius == nil ? header.dockedButtonInset : 0)
        )
        .padding(.top, panelRadius == nil ? header.dockedButtonInset : header.buttonTop)
    }

    /// The pin button's distance from the panel's top and from its edge: the same, so that their corners share a centre (docked: the container is flush with the terminal card's top and with the tabs' edge).
    private var pinGap: Double { panelRadius == nil ? layout.tabSideInset : header.buttonTop }
    private var pinRadius: Double {
        guard let panelRadius else { return layout.pinButtonRadius }
        return ConcentricRadius.inner(outer: panelRadius, inset: pinGap)
    }
}
