import SunsetConfig
import SunsetHelp
import SunsetMetrics
import SunsetPane
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// Help's page, built as the settings': the settings' sections on the left, in their order and with their pictures, the
/// topics of the one shown under it (all of them while searching), Settings last; the chosen topic on the right, under
/// its section's name.
struct HelpPage: View {
    @Bindable var content: HelpContent
    /// The pane's backdrop and top inset, as Settings'.
    let context: PaneViewContext
    private let config = AppConfiguration.shared

    var body: some View {
        // Too narrow for the list beside the topic, the list is a menu over it, as Settings'.
        ListBesidePage(context: context) { narrow in laidOut(narrow: narrow) }
    }

    @ViewBuilder private func laidOut(narrow: Bool) -> some View {
        let shown = ScrollView { HelpTopicView(topic: content.topic) { content.topic = $0 } }.bouncesOnlyWhenScrolling()
        if narrow {
            VStack(spacing: 0) {
                HStack(spacing: Design.Space.s) {
                    topicMenu
                    TextField("Search Help", text: $content.query).textFieldStyle(.plain).fieldSurface()
                }
                .padding(Design.Space.m)
                Divider()
                shown
            }
        } else {
            HStack(spacing: 0) {
                VStack(spacing: Design.Space.s) {
                    TextField("Search Help", text: $content.query).textFieldStyle(.plain).fieldSurface()
                    ScrollView { list }
                        .bouncesOnlyWhenScrolling()
                        .scrollIndicators(.never)
                }
                .padding(Design.Space.m)
                .frame(width: Design.Size.settingsList)
                Divider()
                shown
            }
        }
    }

    /// The sections and their topics as a menu, for a narrow pane.
    private var topicMenu: some View {
        Menu {
            ForEach(HelpTree.sections(content.listed)) { section in
                Section(SettingsSection.all.first { $0.id == section.id }?.title ?? section.id) {
                    ForEach(section.topics) { topic in
                        Button(HelpCatalog.entry(topic).title) { content.topic = topic }
                    }
                }
            }
        } label: {
            Label(HelpCatalog.entry(content.topic).title, systemImage: "list.bullet").lineLimit(1)
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var list: some View {
        let layout = ShellSettings(config.configuration).layout
        let searching = !content.query.trimmingCharacters(in: .whitespaces).isEmpty
        return VStack(spacing: layout.tabSpacing) {
            ForEach(HelpTree.sections(content.listed)) { section in
                let settings = SettingsSection.all.first { $0.id == section.id }
                SettingsListRow(
                    title: settings?.title ?? section.id,
                    symbol: settings?.symbol ?? PaneDescriptor.helpSymbol,
                    selected: false,
                    layout: layout
                ) {
                    if let first = section.topics.first { content.topic = first }
                }
                if searching || section.id == content.topic.settingsSection {
                    ForEach(section.topics) { topic in
                        SettingsListRow(
                            title: HelpCatalog.entry(topic).title,
                            symbol: nil,
                            selected: topic == content.topic,
                            layout: layout
                        ) { content.topic = topic }
                    }
                }
            }
            if let tabs = content.tabs {
                SettingsListRow(
                    title: "Settings",
                    symbol: PaneDescriptor.settingsSymbol,
                    selected: false,
                    layout: layout
                ) {
                    AppSettings.show(content.topic.settingsTopic, in: tabs)
                }
            }
        }
        .animation(layout.smooth, value: content.topic.settingsSection)
    }
}
