import SunsetConfig
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// The page of the settings in a pane (roadmap 0032): the options of the topic shown, or what the search finds under each
/// option's section and topic. Edits go to the file (saved a moment after the last change) and the windows follow at once; a
/// hand edit of the file shows up here too. With no docked sidebar showing the list of sections and topics, the page has it at
/// its side, with a search field.
struct SettingsPage: View {
    @Bindable var content: SettingsContent
    let context: PaneViewContext
    private let config = AppConfiguration.shared

    private static let entries = SettingsOption.all.map(\.entry)
    private var results: [SettingsOption] {
        SettingsSearch.matches(content.query, in: Self.entries).compactMap { SettingsOption.named($0.id) }
    }
    private var ownList: Bool {
        content.tabs?.settingsListInPage(sidebarDocked: config.configuration.sidebarDocked) ?? true
    }

    var body: some View {
        HStack(spacing: 0) {
            if ownList {
                VStack(spacing: Design.Space.s) {
                    TextField("Search Settings", text: $content.query).textFieldStyle(.plain).fieldSurface()
                    ScrollView {
                        SettingsTopicList(content: content, layout: ShellSettings(config.configuration).layout)
                    }
                    .scrollIndicators(.never)
                }
                .padding(Design.Space.m)
                .frame(width: Design.Size.settingsList)
                Divider()
            }
            page
        }
        .padding(.top, context.topInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // On the terminal's background, as every pane (the owner, 2026-11-15).
        .paneBackdrop(context.backdrop)
        .simultaneousGesture(TapGesture().onEnded { content.onFocusRequest() })
    }

    private var page: some View {
        Form {
            if content.isSearching {
                if results.isEmpty { ContentUnavailableView.search(text: content.query) }
                ForEach(SettingsSearch.panes(of: results.map(\.entry)), id: \.self) { topic in
                    Section(SettingsSection.heading(of: topic)) { rows(results.filter { $0.topic == topic }) }
                }
            } else if let shown = SettingsSection.topic(content.topic) {
                Section(shown.section.title + " \u{203A} " + shown.topic.title) { rows(shown.topic.options) }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: Design.Size.settingsPage)
        .frame(maxWidth: .infinity)
    }

    private func rows(_ options: [SettingsOption]) -> some View {
        ForEach(options) { option in SettingsRow(option: option, config: config) }
    }
}
