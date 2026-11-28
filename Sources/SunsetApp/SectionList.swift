import SunsetHelp
import SunsetMetrics
import SunsetPane
import SunsetShell
import SunsetShellModel
import SunsetWeb
import SunsetWebModel
import SwiftUI

/// The rows of a section under their headings: the pages of the history by day, the documents in the chosen order, the
/// downloads by day; or a line that says there is nothing, or nothing that matches.
struct SectionList: View {
    let tabs: TabsModel
    let section: SidebarSection
    let layout: LayoutMetrics
    let sort: DocumentSort
    let query: String
    private var changes = HistoryChanges.shared
    @AppStorage("history.profiles") private var historyProfiles = HistoryProfiles.all.rawValue

    init(tabs: TabsModel, section: SidebarSection, layout: LayoutMetrics, sort: DocumentSort, query: String) {
        self.tabs = tabs
        self.section = section
        self.layout = layout
        self.sort = sort
        self.query = query
    }

    private var searching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        switch section {
            case .history:
                let _ = changes.generation
                let pages = AppHistory.shared?.entries(matching: query) ?? []
                groups(historyGroups(pages), none: "No pages visited yet", noMatch: "No page matches") {
                    HistoryRow(entry: $0, layout: layout, profile: PaneContentKinds.profile(of: tabs))
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
                    help: { AppHelp.show(HelpTree.topic(about: AppSettings.content(in: tabs)?.topic), in: tabs) }
                )
            case .passwords:
                PasswordsSection(layout: layout, query: query, tabs: tabs)
            case .tabs:
                EmptyView()
        }
    }

    /// The history by day: every profile's, this window's profile's only, or under each profile (`HistoryProfiles`).
    private func historyGroups(_ pages: [HistoryEntry]) -> [ListGroup<HistoryEntry>] {
        let profiles = AppSpaces.all.profiles.profiles.map(\.profile)
        guard profiles.count > 1 else { return ListGroup.days(pages, by: \.lastVisit) }
        let current = AppSpaces.all.profiles.profile(of: tabs.space.space).profile.id.uuidString
        switch HistoryProfiles(rawValue: historyProfiles) ?? .all {
            case .all: return ListGroup.days(pages, by: \.lastVisit)
            case .current: return ListGroup.days(pages.filter { $0.isVisited(in: current) }, by: \.lastVisit)
            case .grouped:
                return profiles.compactMap { profile in
                    let visited = pages.filter { $0.isVisited(in: profile.id.uuidString) }
                    return visited.isEmpty ? nil : ListGroup(title: profile.name, elements: visited)
                }
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
