import SunsetConfig
import SunsetMetrics
import SunsetPane
import SunsetShell
import SwiftUI

/// The sections of the settings and, under the one shown, its topics: in the tab sidebar while the Library is on its Settings
/// section, and at the side of the page when the sidebar does not show it. A section's row shows its first topic.
struct SettingsTopicList: View {
    /// The window's page of settings; nil when it has none yet (a row then opens it).
    let content: SettingsContent?
    let layout: LayoutMetrics
    /// A row was chosen: its tag (a topic, or a section's).
    var choose: ((String) -> Void)?
    /// Help was chosen (a Help section in Settings); nil, no Help row.
    var help: (() -> Void)?

    private var shown: (section: SettingsSection, topic: SettingsTopic)? {
        guard let content, !content.isSearching else { return nil }
        return SettingsSection.topic(content.topic)
    }

    var body: some View {
        VStack(spacing: layout.tabSpacing) {
            // With a profile chosen, the sections that have something it can set.
            ForEach(
                SettingsSection.sections(for: AppConfiguration.shared.configuration.features)
                    .filter { content?.scope == nil || $0.topics.contains(where: \.hasProfileSettings) }
            ) { section in
                // The feature scopes' sections after the app's, under a heading of their own.
                if section.id == firstScope {
                    Text("Features")
                        .font(Design.Text.detail.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Design.Space.m)
                        .padding(.leading, layout.tabPaddingLeading)
                        .accessibilityAddTraits(.isHeader)
                }
                row(
                    section.title,
                    symbol: section.symbol,
                    selected: false,
                    tag: SettingsSection.sectionPrefix + section.id
                )
                if section.id == shown?.section.id {
                    // With a profile chosen, the topics it can set.
                    ForEach(section.topics.filter { content?.scope == nil || $0.hasProfileSettings }) { topic in
                        row(topic.title, symbol: nil, selected: topic.id == shown?.topic.id, tag: topic.id)
                    }
                }
            }
            if let help {
                SettingsListRow(
                    title: "Help",
                    symbol: PaneDescriptor.helpSymbol,
                    selected: false,
                    layout: layout,
                    action: help
                )
            }
        }
        .animation(layout.smooth, value: shown?.section.id)
    }

    /// The first scope's section listed now.
    private var firstScope: String? {
        SettingsSection.sections(for: AppConfiguration.shared.configuration.features).first(where: \.isScope)?.id
    }

    private func row(_ title: String, symbol: String?, selected: Bool, tag: String) -> some View {
        SettingsListRow(title: title, symbol: symbol, selected: selected, layout: layout) {
            if let choose { choose(tag) } else { content?.show(tag) }
        }
    }
}
