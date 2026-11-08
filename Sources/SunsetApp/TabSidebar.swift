import SunsetConfig
import SunsetHost
import SwiftUI

/// The sidebar: the tabs of the window, listed vertically (the same `TabList` the built-in bar shows), and nothing else. It has no background of its own
/// (the window's own colour or material shows through, with the window's settings) and is not a system list: the rows are `SidebarRow`s in a scroll view whose
/// content starts below the traffic lights and scrolls beneath them, fading out there. A click selects a tab, a drag reorders them.
struct TabSidebar: View {
    let tabs: TabsModel
    let settings: Configuration
    /// The floating panel: its traffic lights are a little further from the corner.
    var floating = false

    private var margin: Double { settings.sidebar.padding }
    /// The metrics the tabs draw with: the docked ones, or the floating panel's own.
    private var layout: Configuration.Layout { floating ? settings.layout.floatingTabs : settings.layout }
    private var header: SidebarHeader { SidebarHeader(layout: layout, margin: margin, floating: floating) }
    private var topInset: Double { header.height }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: layout.tabSpacing) {
                ForEach(tabs.list.tabs) { tab in row(tab) }
            }
            .padding(.horizontal, layout.tabSideInset)
        }
        .scrollIndicators(.never)
        .contentMargins(.top, topInset, for: .scrollContent)
        .contentMargins(.bottom, margin, for: .scrollContent)
        .mask { fade }
        .overlay(alignment: .topTrailing) { pinButton }
    }

    /// Content that scrolls up past the traffic lights fades out over the height of the strip they sit in; rows at rest start below it, untouched.
    private var fade: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: max(topInset - 4, 0))
            Color.black
        }
    }

    private func row(_ tab: TabList.Tab) -> some View {
        SidebarRow(
            model: tabs.models[tab.id],
            selected: tab.id == tabs.list.selectedID,
            showTitle: settings.tabs.bar.showTitle,
            showDirectory: settings.tabs.bar.showDirectory,
            showProgress: settings.tabs.bar.showProgress,
            layout: layout,
            close: { tabs.close(tab.id) }
        )
        .onTapGesture { tabs.select(tab.id) }
        .draggable(tab.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard let text = items.first, let id = UUID(uuidString: text),
                let index = tabs.list.tabs.firstIndex(where: { $0.id == tab.id })
            else { return false }
            tabs.move(id, to: index)
            return true
        }
        .contextMenu {
            Button("Close Tab") { tabs.close(tab.id) }
            Button("Close Other Tabs") {
                for other in tabs.list.tabs where other.id != tab.id { tabs.close(other.id) }
            }
            .disabled(tabs.list.count < 2)
        }
    }

    /// Pins the sidebar beside the terminal (`sidebar.autoHide` off) or lets it hide and float: the sidebar symbol, filled while the sidebar is open
    /// (pinned) and outlined while it only appears on hover. Its container is a rounded square the size of the hit box, highlighted under the pointer like a
    /// tab, with its trailing edge on the tabs' trailing edge and its middle on the traffic lights'.
    private var pinButton: some View {
        PinButton(pinned: !settings.sidebar.autoHide, layout: layout) {
            AppConfiguration.shared.update { $0.sidebar.autoHide.toggle() }
        }
        .padding(.trailing, margin)
        .padding(.top, header.buttonTop)
    }
}
