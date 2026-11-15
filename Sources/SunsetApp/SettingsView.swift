import SunsetConfig
import SunsetShell
import SwiftUI

/// The Settings window: a sidebar of panes with a search field, in the manner of System Settings. Every option of the configuration file has a control; the
/// search finds options by name and by related words and shows them (with their controls) whatever pane they are in. Edits go to the file (saved a moment
/// after the last change) and the open windows follow at once; a hand edit of the file shows up here too.
struct SettingsView: View {
    let config = AppConfiguration.shared
    @State private var selection: SettingsPane? = .font
    @State private var query = ""
    @FocusState private var searching: Bool

    private static let entries = SettingsOption.all.map(\.entry)
    private var results: [SettingsOption] {
        SettingsSearch.matches(query, in: Self.entries).compactMap { SettingsOption.named($0.id) }
    }
    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationSplitView {
            List(SettingsPane.allCases, selection: $selection) { pane in
                Label(pane.title, systemImage: pane.symbol).tag(pane)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
        } detail: {
            detail
        }
        .searchable(text: $query, placement: .sidebar, prompt: "Search")
        .searchFocused($searching)
        // The window opens with the search field ready to type in, as System Settings does (not in the first text field of a pane).
        .onAppear { searching = true }
        .frame(minWidth: 700, minHeight: 480)
        .frame(width: 760, height: 560)
    }

    @ViewBuilder private var detail: some View {
        if isSearching {
            searchResults
        } else if let pane = selection {
            Form { rows(of: pane.options) }
                .formStyle(.grouped)
                .navigationTitle(pane.title)
        }
    }

    private var searchResults: some View {
        Form {
            if results.isEmpty {
                ContentUnavailableView.search(text: query)
            }
            ForEach(SettingsSearch.panes(of: results.map(\.entry)), id: \.self) { paneID in
                Section(SettingsPane(rawValue: paneID)?.title ?? paneID) {
                    rows(of: results.filter { $0.pane == paneID })
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
