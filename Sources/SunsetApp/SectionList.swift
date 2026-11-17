import SunsetMetrics
import SunsetShell
import SunsetWeb
import SwiftUI

/// The rows of a section under their headings (roadmap 0031): the pages of the history by day, the documents in the chosen
/// order, the downloads by day; or a line that says there is nothing, or nothing that matches.
struct SectionList: View {
    let tabs: TabsModel
    let section: SidebarSection
    let layout: LayoutMetrics
    let sort: DocumentSort
    let query: String
    private var changes = HistoryChanges.shared

    init(tabs: TabsModel, section: SidebarSection, layout: LayoutMetrics, sort: DocumentSort, query: String) {
        self.tabs = tabs
        self.section = section
        self.layout = layout
        self.sort = sort
        self.query = query
    }

    private var searching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        switch section {
            case .history:
                let _ = changes.generation
                let pages = AppHistory.shared?.entries(matching: query) ?? []
                groups(ListGroup.days(pages, by: \.lastVisit), none: "No pages visited yet", noMatch: "No page matches")
                {
                    HistoryRow(entry: $0, layout: layout)
                }
            case .documents:
                let found = ShelfDocument.matching(query, in: tabs.listedDocuments)
                groups(sort.groups(found), none: noDocuments, noMatch: "No document matches") {
                    DocumentSectionRow(
                        tabs: tabs,
                        document: $0,
                        layout: layout,
                        byDay: sort == .changed || sort == .made
                    )
                }
            case .downloads:
                let center = DownloadCenter.shared
                let found = center.items.filter { !searching || $0.name.localizedCaseInsensitiveContains(query) }
                groups(ListGroup.days(found, by: \.started), none: "Nothing downloaded", noMatch: "No download matches")
                {
                    DownloadRow(item: $0, center: center).padding(.horizontal, layout.tabPaddingLeading)
                }
            case .settings:
                SettingsTopicList(
                    content: AppSettings.content(in: tabs),
                    layout: layout,
                    choose: { AppSettings.show($0, in: tabs) },
                    help: { AppHelp.show(in: tabs) }
                )
            case .tabs:
                EmptyView()
        }
    }

    private var noDocuments: String {
        if tabs.isPrivateWindow { return "Documents are not listed in a private window" }
        return tabs.shelf.available() ? "No documents yet" : "Nothing can be kept in this run: see Settings, Storage"
    }

    @ViewBuilder
    private func groups<Element: Identifiable, Row: View>(
        _ groups: [ListGroup<Element>],
        none: String,
        noMatch: String,
        @ViewBuilder row: @escaping (Element) -> Row
    ) -> some View {
        if groups.isEmpty {
            Text(searching ? noMatch : none)
                .foregroundStyle(.secondary)
                .padding(.leading, layout.tabPaddingLeading)
                .padding(.top, Design.Space.m)
        }
        ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
            if let title = group.title { heading(title) }
            ForEach(group.elements) { row($0) }
        }
    }

    /// A day or a kind, as the sidebar's section titles.
    private func heading(_ title: String) -> some View {
        Text(title)
            .font(Design.Text.detail.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, layout.tabPaddingLeading)
            .padding(.top, Design.Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
