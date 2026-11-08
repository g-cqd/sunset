import SunsetConfig
import SunsetHost
import SwiftUI

/// The sidebar: the tabs of the window, listed vertically (the same `TabList` the built-in bar shows), and nothing else. It has no background of its own
/// (the window's colour or material shows; `sidebar.material` can add one) and is not a system list: the rows are `SidebarRow`s in a scroll view whose
/// content starts below the traffic lights and scrolls beneath them, fading out there. A click selects a tab, a drag reorders them.
struct TabSidebar: View {
    let tabs: TabsModel
    let settings: Configuration
    /// Where the first row starts, from the window's top: below the traffic lights.
    let topInset: Double
    /// From the panel's top, the middle of the traffic lights' row: the pin button is centred on it.
    let lightsMiddle: Double

    private var margin: Double { settings.sidebar.padding }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(tabs.list.tabs) { tab in row(tab) }
            }
            .padding(.horizontal, margin)
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

    /// Keeps the sidebar beside the terminal (pinned) or lets it hide and float (`sidebar.autoHide`).
    private var pinButton: some View {
        let pinned = !settings.sidebar.autoHide
        return Button {
            AppConfiguration.shared.update { $0.sidebar.autoHide.toggle() }
        } label: {
            Image(systemName: pinned ? "pin.fill" : "pin")
                .font(.system(size: 10, weight: .medium))
                .frame(width: 20, height: 20)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(pinned ? "Let the sidebar hide" : "Keep the sidebar visible")
        .padding(.trailing, margin)
        .padding(.top, max(lightsMiddle - 10, 0))
        .animation(SidebarRow.smooth, value: pinned)
    }
}
