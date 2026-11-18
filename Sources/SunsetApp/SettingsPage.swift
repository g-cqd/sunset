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
    private static let byID = Dictionary(
        SettingsOption.all.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )
    private var results: [SettingsOption] {
        let features = config.configuration.features
        return SettingsSearch.matches(content.query, in: Self.entries)
            .compactMap { Self.byID[$0.id] }
            // The settings of a scope that is off are not found (roadmap 0033).
            .filter { SettingsSection.showsTopic($0.topic, features) }
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
                    .bouncesOnlyWhenScrolling()
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
                // Searched once a keystroke, then grouped: the results were searched again for each topic shown (note n15).
                let found = results
                let byTopic = Dictionary(grouping: found, by: \.topic)
                if found.isEmpty { ContentUnavailableView.search(text: content.query) }
                ForEach(SettingsSearch.panes(of: found.map(\.entry)), id: \.self) { topic in
                    Section(SettingsSection.heading(of: topic)) { rows(byTopic[topic] ?? []) }
                }
            } else if let shown = SettingsSection.topic(content.topic) {
                // A topic of measures only (the floating sidebar's) shows them at once: a page with only More is empty.
                let plain = shown.topic.first.isEmpty ? shown.topic.further : shown.topic.first
                let heading = shown.section.title + " \u{203A} " + shown.topic.title
                blocks(SettingsBlock.blocks(plain), heading: heading)
                // The measures and the finer choices a level down (roadmap 0047 G).
                if !shown.topic.first.isEmpty, !shown.topic.further.isEmpty {
                    Section {
                        DisclosureGroup("More", isExpanded: $content.showsMore) {}
                    }
                    if content.showsMore { blocks(SettingsBlock.blocks(shown.topic.further), heading: nil) }
                }
            }
        }
        .formStyle(.grouped)
        // Every setting that turns something on or off is a switch, wherever its row puts it (note n6).
        .settingSwitch()
        .scrollContentBackground(.hidden)
        .frame(maxWidth: Design.Size.settingsPage)
        .frame(maxWidth: .infinity)
    }

    /// Each block a section (the owner's note n13): a group under its heading, a list under its title with its note under
    /// it; the page's heading above the first.
    private func blocks(_ blocks: [SettingsBlock], heading: String?) -> some View {
        ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
            Section {
                if block.isList, let list = block.options.first {
                    SettingsRow.list(list, config: config)
                    // Its note right under it when other rows follow it, else under the section.
                    if block.options.count > 1, let note = list.note {
                        Text(RichText.attributed(note)).font(Design.Text.detail).foregroundStyle(.secondary)
                    }
                    rows(Array(block.options.dropFirst()))
                } else {
                    rows(block.options)
                }
            } header: {
                SettingsBlockHeader(page: index == 0 ? heading : nil, block: block)
            } footer: {
                if block.isList, block.options.count == 1, let note = block.options.first?.note {
                    Text(RichText.attributed(note)).font(Design.Text.detail).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func rows(_ options: [SettingsOption]) -> some View {
        ForEach(options) { option in SettingsRow(option: option, config: config) }
    }
}
