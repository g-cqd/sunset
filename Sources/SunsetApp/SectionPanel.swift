import SunsetConfig
import SunsetMetrics
import SunsetShell
import SunsetWeb
import SwiftUI

/// One section of a sidebar (roadmap 0031): History, Documents or Downloads, the same list in the panel opposite the tabs and
/// in the Library of the tab sidebar. Built on the sidebar's parts (owner note n67): a title, a search field where the
/// sidebar's address field is, the rows as sidebar rows under their headings; the list scrolls under the top, fading and
/// blurring there as the sidebar's.
struct SectionPanel: View {
    /// Where it is shown.
    enum Place {
        /// Opposite the tabs: the title on the window buttons' row with a hide button, the switch between sections at the foot.
        case opposite
        /// In the tab sidebar, beside the Library's rail: the title under the window buttons' row, which keeps the pin.
        case library
    }

    let tabs: TabsModel
    let section: SidebarSection
    let buttons: SidebarButtons
    let sort: DocumentSort
    let place: Place
    @State var query = ""
    /// The Library opens with its search field ready: typing searches, Escape goes back to the tabs.
    @FocusState var searching: Bool

    var layout: LayoutMetrics { buttons.layout }
    /// How many things the section lists, whatever is searched: with none there is no search field.
    var count: Int {
        switch section {
            case .documents: return tabs.shelf.list().count
            case .history:
                let _ = HistoryChanges.shared.generation
                return AppHistory.shared?.entries(limit: 1).count ?? 0
            case .downloads: return DownloadCenter.shared.items.count
            case .tabs, .settings: return 0
        }
    }
    /// The measures of the title's row and of the field under it.
    var topMeasures: SectionTop {
        SectionTop(buttons: buttons, underLights: place == .library, searchable: section.isSearched(count: count))
    }
    /// Where the list starts: under the title and the field, as the sidebar's rows start under its accessory.
    var listTop: Double { topMeasures.listTop }
    /// The room the switch takes at the foot.
    var footInset: Double { place == .opposite ? buttons.barRoom : 0 }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: layout.tabSpacing) {
                // What was searched for is forgotten with the field (the last document deleted while searching).
                SectionList(
                    tabs: tabs,
                    section: section,
                    layout: layout,
                    sort: sort,
                    query: topMeasures.searchable ? query : ""
                )
            }
            .padding(.horizontal, layout.tabSideInset)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.never)
        .contentMargins(.top, listTop, for: .scrollContent)
        .contentMargins(.bottom, buttons.margin + footInset, for: .scrollContent)
        .mask { fade }
        .overlay(alignment: .top) { topBlur }
        .overlay(alignment: .top) { top }
        .overlay(alignment: .bottom) { foot }
        .onChange(of: section) { _, _ in query = "" }
        // The settings' search is the page's: what is typed here goes there, and a row chosen there ends it here.
        .onChange(of: query) { _, new in if section == .settings { AppSettings.search(new, in: tabs) } }
        .onChange(of: AppSettings.content(in: tabs)?.query) { _, new in
            if section == .settings, let new, new != query { query = new }
        }
        .onChange(of: topMeasures.searchable) { _, searchable in if !searchable { query = "" } }
        .onAppear { if place == .library { searching = true } }
    }
}
