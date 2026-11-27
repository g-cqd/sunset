import SunsetConfig
import SunsetShell
import SwiftUI

/// The sections and their topics as a menu, over a Settings page too narrow for the list at its side (the owner,
/// 2026-11-27: the page did not fit a narrow pane).
struct SettingsTopicMenu: View {
    @Bindable var content: SettingsContent
    let features: Configuration.Features

    var body: some View {
        Menu {
            ForEach(SettingsSection.sections(for: features)) { section in
                Section(section.title) {
                    ForEach(section.topics.filter { SettingsSection.showsTopic($0.id, features) }) { topic in
                        Button(topic.title) { content.show(topic.id) }
                    }
                }
            }
        } label: {
            Label(SettingsSection.heading(of: content.topic), systemImage: "list.bullet")
                .lineLimit(1)
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: false, vertical: true)
    }
}
