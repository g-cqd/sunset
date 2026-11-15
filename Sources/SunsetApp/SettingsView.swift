import SunsetConfig
import SunsetShell
import SwiftUI

/// The Settings window: a sidebar of sections with a search field, in the manner of System Settings; under the section shown,
/// its topics, each a page of options (roadmap 0032). Every option of the configuration file has a control (`SettingsOption`,
/// where each is declared once); search finds options by name and by related words and shows them, with their controls, under
/// their section and topic. Edits go to the file (saved a moment after the last change) and the open windows follow at once; a
/// hand edit of the file shows up here too.
struct SettingsView: View {
    let config = AppConfiguration.shared
    /// A topic's identifier; a section's row sets its own tag, which becomes the section's first topic.
    @State private var selection: String? = SettingsSection.all.first?.topics.first?.id
    @State private var query = ""
    @FocusState private var searching: Bool

    private static let entries = SettingsOption.all.map(\.entry)
    private var results: [SettingsOption] {
        SettingsSearch.matches(query, in: Self.entries).compactMap { SettingsOption.named($0.id) }
    }
    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }
    /// The topic shown, and its section.
    private var shown: (section: SettingsSection, topic: SettingsTopic)? {
        SettingsSection.shown(for: selection).flatMap(SettingsSection.topic)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SettingsSection.all) { section in
                    Label(section.title, systemImage: section.symbol)
                        .tag(SettingsSection.sectionPrefix + section.id)
                    if section.id == shown?.section.id {
                        ForEach(section.topics) { topic in
                            Text(topic.title).padding(.leading, Design.Space.xl + Design.Space.m).tag(topic.id)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
        } detail: {
            detail
        }
        .searchable(text: $query, placement: .sidebar, prompt: "Search")
        .searchFocused($searching)
        // The window opens with the search field ready to type in, as System Settings does (not in the first text field of a page).
        .onAppear { searching = true }
        // A section's row shows its first topic, which is then the row selected.
        .onChange(of: selection) { _, new in
            if new?.hasPrefix(SettingsSection.sectionPrefix) == true { selection = SettingsSection.shown(for: new) }
        }
        .frame(minWidth: 720, minHeight: 480)
        .frame(width: 780, height: 560)
    }

    @ViewBuilder private var detail: some View {
        if isSearching {
            searchResults
        } else if let shown {
            Form { rows(of: shown.topic.options) }
                .formStyle(.grouped)
                .navigationTitle(shown.section.title + " \u{203A} " + shown.topic.title)
        }
    }

    private var searchResults: some View {
        Form {
            if results.isEmpty {
                ContentUnavailableView.search(text: query)
            }
            ForEach(SettingsSearch.panes(of: results.map(\.entry)), id: \.self) { topic in
                Section(SettingsSection.heading(of: topic)) {
                    rows(of: results.filter { $0.topic == topic })
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Search")
    }

    private func rows(of options: [SettingsOption]) -> some View {
        ForEach(options) { option in SettingsRow(option: option, config: config) }
    }
}
