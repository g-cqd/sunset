import SunsetConfig
import SunsetMetrics
import SunsetShell
import SwiftUI

/// The sections of the settings and, under the one shown, its topics (roadmap 0032): in the tab sidebar while the Library is on
/// its Settings section, and at the side of the page when the sidebar does not show it. A section's row shows its first topic.
struct SettingsTopicList: View {
    /// The window's page of settings; nil when it has none yet (a row then opens it).
    let content: SettingsContent?
    let layout: LayoutMetrics
    /// A row was chosen: its tag (a topic, or a section's).
    var choose: ((String) -> Void)?

    private var shown: (section: SettingsSection, topic: SettingsTopic)? {
        guard let content, !content.isSearching else { return nil }
        return SettingsSection.topic(content.topic)
    }

    var body: some View {
        VStack(spacing: layout.tabSpacing) {
            ForEach(SettingsSection.all) { section in
                row(
                    section.title,
                    symbol: section.symbol,
                    selected: false,
                    tag: SettingsSection.sectionPrefix + section.id
                )
                if section.id == shown?.section.id {
                    ForEach(section.topics) { topic in
                        row(topic.title, symbol: nil, selected: topic.id == shown?.topic.id, tag: topic.id)
                    }
                }
            }
        }
        .animation(layout.smooth, value: shown?.section.id)
    }

    private func row(_ title: String, symbol: String?, selected: Bool, tag: String) -> some View {
        SettingsListRow(title: title, symbol: symbol, selected: selected, layout: layout) {
            if let choose { choose(tag) } else { content?.show(tag) }
        }
    }
}
