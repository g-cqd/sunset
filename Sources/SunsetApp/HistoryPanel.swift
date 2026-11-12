import SunsetConfig
import SunsetMetrics
import SunsetShell
import SunsetWeb
import SwiftUI

/// The history panel (web step e): a column on the side opposite the tabs, with the sidebar's width and look. A search field, then the pages by day;
/// a click opens one in the focused page (a new page tab when a terminal has the keyboard), Cmd-click in a new tab; each has a menu.
struct HistoryPanel: View {
    let tabs: TabsModel
    let layout: Configuration.Layout
    @State private var query = ""
    private var changes = HistoryChanges.shared

    init(tabs: TabsModel, layout: Configuration.Layout) {
        self.tabs = tabs
        self.layout = layout
    }

    var body: some View {
        let _ = changes.generation
        let days = HistoryDays.group(AppHistory.shared?.entries(matching: query) ?? [])
        VStack(spacing: Design.Space.m) {
            HStack {
                Text("History").font(Design.Text.title)
                Spacer()
                Button {
                    tabs.showsHistory = false
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
                .buttonStyle(.borderless)
                .help("Hide History (Cmd-Y)")
            }
            TextField("Search History", text: $query).textFieldStyle(.plain).fieldSurface()
            if days.isEmpty {
                Text(query.isEmpty ? "No pages visited yet" : "No page matches")
                    .foregroundStyle(.secondary)
                    .padding(.top, Design.Space.l)
                Spacer()
            } else {
                list(days)
            }
        }
        .padding(.horizontal, layout.tabSideInset + Design.Space.m)
        .padding(.vertical, Design.Space.l)
    }

    private func list(_ days: [HistoryDays]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Design.Space.hair, pinnedViews: .sectionHeaders) {
                ForEach(days, id: \.title) { day in
                    Section {
                        ForEach(day.entries) { entry in HistoryRow(entry: entry, radius: layout.tabRadius) }
                    } header: {
                        Text(day.title)
                            .font(Design.Text.detail.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, Design.Space.m)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .scrollIndicators(.never)
    }
}
