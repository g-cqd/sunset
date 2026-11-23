import SunsetAppCore
import SunsetConfig
import SunsetMetrics
import SunsetRuntime
import SunsetShell
import SunsetWeb
import SwiftUI

/// One section of a sidebar: History, Documents or Downloads, the same list in the panel opposite the tabs and in the
/// Library of the tab sidebar. Built on the sidebar's parts: a title, a search field where the sidebar's address field
/// is, the rows as sidebar rows under their headings; the list scrolls under the top, fading and blurring there as the
/// sidebar's.
struct SectionPanel: View {
    @Environment(\.runtime) var runtime

    /// The ends fade out, or are cut (`appearance.ends`).
    @Environment(\.fadesEnds) var fadesEnds
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
    /// The list itself has the keyboard: a section with nothing to search, or a click beside its rows. Escape then goes
    /// back to the tabs too (from anywhere in the Library).
    @FocusState var inList: Bool
    /// How far the rows are scrolled down: the fade under the field grows with it.
    @State var scrolledBy = 0.0

    var layout: LayoutMetrics {
        buttons.layout
    }
    /// How many things the section lists, whatever is searched: with none there is no search field.
    var count: Int {
        switch section {
            case .documents: return tabs.listedDocuments.count
            case .history:
                let _ = HistoryChanges.shared.generation
                return AppHistory.shared?.entries(limit: 1).count ?? 0
            case .downloads: return DownloadCenter.shared.items.count
            case .passwords: return AppPasswords.model.entries.count
            case .tabs, .settings: return 0
        }
    }
    /// The measures of the title's row and of the field under it.
    var topMeasures: SectionTop {
        SectionTop(buttons: buttons, underLights: place == .library, searchable: section.isSearched(count: count))
    }
    /// Where the list starts: under the title and the field, as the sidebar's rows start under its accessory.
    var listTop: Double {
        topMeasures.listTop
    }
    /// The room the switch takes at the foot.
    var footInset: Double {
        place == .opposite ? buttons.barRoom : 0
    }

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
        .bouncesOnlyWhenScrolling()
        .scrollIndicators(.never)
        // Under the rows: a click beside them gives the Library the keyboard. On a row it does what the row does.
        .background(Color.clear.contentShape(Rectangle()).onTapGesture { if place == .library { inList = true } })
        .focusable(place == .library)
        .focusEffectDisabled()
        .focused($inList)
        .onExitCommand { escape() }
        .contentMargins(.top, listTop, for: .scrollContent)
        .onScrollGeometryChange(for: Double.self, of: { Double($0.contentOffset.y + $0.contentInsets.top) }) {
            scrolledBy = max($1, 0)
        }
        .contentMargins(
            .bottom,
            FootFade.margin(buttons.margin, faded: place == .opposite) + footInset,
            for: .scrollContent
        )
        .mask { fade }
        .overlay(alignment: .top) { top }
        .overlay(alignment: .bottom) { foot }
        .onChange(of: section) { _, _ in
            query = ""
            takeKeyboard()
        }
        // The settings' search is the page's: what is typed here goes there, and a row chosen there ends it here.
        .onChange(of: query) { _, new in if section == .settings { AppSettings.search(new, in: tabs) } }
        .onChange(of: AppSettings.content(in: tabs)?.query) { _, new in
            if section == .settings, let new, new != query { query = new }
        }
        .onChange(of: topMeasures.searchable) { _, searchable in if !searchable { query = "" } }
        .onAppear { takeKeyboard() }
    }

    /// The Library has the keyboard when it opens and when its section changes: in its search field, or, with nothing to
    /// search, on its list. The panel opposite the tabs never takes it.
    private func takeKeyboard() {
        guard place == .library else { return }
        guard topMeasures.searchable else {
            inList = true
            return
        }
        // In the next turn: a field that comes with this very change (from a section with nothing to search) is not there
        // to take the keyboard yet (seen 2026-11-16: Escape did nothing after Downloads, then Documents).
        runtime.task { @MainActor in searching = true }
    }
}
