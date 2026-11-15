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
    var header: SidebarHeader { buttons.header }
    /// The title's row when it is under the window buttons' row.
    var titleRow: Double { place == .library ? layout.closeButtonSize + layout.tabSpacing : 0 }
    /// Where the list starts: under the header, the title and the field, as the sidebar's rows start under its accessory.
    var listTop: Double { header.height + titleRow + Design.Size.field + layout.tabSpacing + Design.Space.xs }
    /// The room the switch takes at the foot.
    var footInset: Double { place == .opposite ? buttons.metrics.size.height + layout.tabSpacing : 0 }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: layout.tabSpacing) {
                SectionList(tabs: tabs, section: section, layout: layout, sort: sort, query: query)
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
        .onAppear { if place == .library { searching = true } }
    }
}
