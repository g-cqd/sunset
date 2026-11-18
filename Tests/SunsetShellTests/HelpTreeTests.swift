import SunsetConfig
import SunsetHelp
import Testing

/// The owner's note n16 (2026-11-18): "the helper window/scope does not have the same kind of tree than the general settings,
/// you could harmonize and uniformize that". Help is listed under the settings' sections, each topic under the section of the
/// settings it is about.
@Suite("Help's tree is the settings'") struct HelpTreeTests {
    @Test func `every topic is about a topic of the settings`() {
        let ids = Set(SettingsSection.all.flatMap(\.topics).map(\.id))
        for topic in HelpTopic.allCases {
            #expect(ids.contains(topic.settingsTopic), "\(topic): “\(topic.settingsTopic)”")
        }
    }

    @Test func `a topic that explains a setting is under that setting's section`() {
        for option in SettingsOption.all {
            guard let topic = HelpTopic.explaining(setting: option.id) else { continue }
            let section = SettingsSection.all.first {
                $0.topics.contains { $0.options.contains { $0.id == option.id } }
            }
            #expect(
                topic.settingsSection == section?.id,
                "\(option.id) is in \(section?.id ?? "?"), \(topic) in \(topic.settingsSection)"
            )
        }
    }

    @Test func `Help from a settings page opens on its topic, else its section's`() {
        #expect(HelpTree.topic(about: "web.downloads") == .downloads)
        #expect(HelpTree.topic(about: "web.proxy")?.settingsSection == "web")
        #expect(HelpTree.topic(about: "appearance.theme") == nil)
        #expect(HelpTree.topic(about: nil) == nil)
    }

    @Test func `the sections are listed in the settings' order`() {
        let order = SettingsSection.all.map(\.id)
        #expect(HelpTree.order == order)
        let listed = HelpTree.sections.map(\.id)
        #expect(listed == order.filter(listed.contains), "\(listed)")
        #expect(HelpTree.sections.flatMap(\.topics).count == HelpTopic.allCases.count)
    }
}
