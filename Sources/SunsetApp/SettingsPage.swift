import SunsetConfig
import SunsetPane
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

    /// The profile chosen at the top, if one is (roadmap 0050).
    private var scoped: ProfileSettingsStore? {
        guard let id = content.scope,
            let profile = AppSpaces.all.profiles.profiles.first(where: { $0.profile.id == id })
        else { return nil }
        return ProfileSettingsStore(profile: profile, profiles: AppSpaces.all.profiles)
    }

    /// Where the rows read and write: the profile chosen, or all profiles.
    private var store: any SettingsStore {
        scoped ?? config
    }

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
            ScopeRow(content: content)
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
                blocks(SettingsBlock.blocks(applying(plain)), heading: heading)
                // The measures and the finer choices a level down (roadmap 0047 G).
                if !shown.topic.first.isEmpty, !shown.topic.further.isEmpty {
                    // The finer choices inside the fold, right under it, each group under its heading (the owner's notes
                    // n32, n33: in sections of their own they were far from it).
                    Section {
                        DisclosureGroup("More", isExpanded: $content.showsMore) {
                            FoldContent {
                                ForEach(SettingsBlock.blocks(applying(shown.topic.further))) { block in
                                    if let title = block.title {
                                        Text(title).font(Design.Text.body.weight(.semibold))
                                            .padding(.top, Design.Space.s)
                                    }
                                    rows(block.options)
                                }
                            }
                        }
                    }
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
            if block.isList, let list = block.options.first, list.ownsSections {
                // Its own sections, one a thing (the profiles, notes n38, n39), the page's heading over the first.
                SettingsRow.list(list, config: store, heading: index == 0 ? heading : nil)
            } else {
                section(block, index: index, heading: heading)
            }
        }
    }

    private func section(_ block: SettingsBlock, index: Int, heading: String?) -> some View {
        Section {
            if block.isList, let list = block.options.first {
                SettingsRow.list(list, config: store)
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

    /// The options that act under the configuration now; a group left empty is not shown (note n29).
    private func applying(_ options: [SettingsOption]) -> [SettingsOption] {
        // With a profile chosen, only what a profile can set (roadmap 0050).
        options.filter { $0.isShown(in: store.configuration) && (scoped == nil || $0.isProfileSetting) }
    }

    private func rows(_ options: [SettingsOption]) -> some View {
        // A choice that acts only under another is shown under it only (the owner's note n29).
        ForEach(applying(options)) { option in
            SettingsRow(option: option, config: store)
            if let scoped, scoped.isOwn(option) { OwnSettingRow(store: scoped, option: option) }
        }
    }
}
