import SunsetMetrics
import SunsetShell
import SunsetWeb
import SwiftUI

/// The history panel (web step e), on the side opposite the tabs, built on the sidebar's parts (owner note n67): the title and its
/// hide button in the slot of the window's buttons, centred on their row; the search field where the sidebar's address field is; the
/// pages as sidebar rows (glyph, title, address), by day; the list scrolls under the top, fading and blurring there as the sidebar's.
/// A click opens a page in the focused page (a new page tab when a terminal has the keyboard), Cmd-click in a new tab.
struct HistoryPanel: View {
    let tabs: TabsModel
    /// The sidebar's metrics (`ShellSettings(configuration).layout`) and margin.
    let layout: LayoutMetrics
    let margin: Double
    @State var query = ""
    var changes = HistoryChanges.shared

    var header: SidebarHeader { SidebarHeader(layout: layout, margin: margin) }
    /// Where the list starts: under the header and the field, as the sidebar's rows start under its accessory.
    var listTop: Double { header.height + Design.Size.field + layout.tabSpacing + Design.Space.xs }

    var body: some View {
        let _ = changes.generation
        let days = HistoryDays.group(AppHistory.shared?.entries(matching: query) ?? [])
        ScrollView {
            LazyVStack(alignment: .leading, spacing: layout.tabSpacing) {
                if days.isEmpty {
                    Text(query.isEmpty ? "No pages visited yet" : "No page matches")
                        .foregroundStyle(.secondary)
                        .padding(.leading, layout.tabPaddingLeading)
                        .padding(.top, Design.Space.m)
                }
                ForEach(days, id: \.title) { day in
                    dayTitle(day.title)
                    ForEach(day.entries) { entry in HistoryRow(entry: entry, layout: layout) }
                }
            }
            .padding(.horizontal, layout.tabSideInset)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.never)
        .contentMargins(.top, listTop, for: .scrollContent)
        .contentMargins(.bottom, margin, for: .scrollContent)
        .mask { fade }
        .overlay(alignment: .top) { topBlur }
        .overlay(alignment: .top) { top }
    }
}
