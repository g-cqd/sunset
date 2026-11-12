import SunsetConfig
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
        VStack(spacing: 8) {
            HStack {
                Text("History").font(.headline)
                Spacer()
                Button {
                    tabs.showsHistory = false
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
                .buttonStyle(.borderless)
                .help("Hide History (Cmd-Y)")
            }
            TextField("Search History", text: $query).textFieldStyle(.roundedBorder)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2, pinnedViews: .sectionHeaders) {
                    ForEach(days, id: \.title) { day in
                        Section {
                            ForEach(day.entries) { entry in HistoryRow(entry: entry, radius: layout.tabRadius) }
                        } header: {
                            Text(day.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .scrollIndicators(.never)
            if days.isEmpty {
                Text(query.isEmpty ? "No pages visited yet" : "No page matches").foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, layout.tabSideInset + 8)
        .padding(.vertical, 10)
    }
}
