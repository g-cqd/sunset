/// Help's list (the owner's note n16): the settings' sections, in their order, each with the topics about its settings.
public enum HelpTree {
    /// A section of the settings, by its id, and the topics under it.
    public struct Section: Sendable, Identifiable {
        public let id: String
        public let topics: [HelpTopic]
    }

    /// The settings' sections in their order (`SettingsSection.all`'s ids, which SunsetHelp does not import).
    public static let order = ["general", "appearance", "window", "tabs", "terminal", "web", "privacy"]

    /// Every section with a topic, its topics in their order; `topics` narrows them (a search's).
    public static func sections(_ topics: [HelpTopic] = HelpTopic.allCases) -> [Section] {
        order.compactMap { id in
            let under = topics.filter { $0.settingsSection == id }
            return under.isEmpty ? nil : Section(id: id, topics: under)
        }
    }

    public static var sections: [Section] {
        sections()
    }

    /// The topic Help opens on from the settings' page `settingsTopic`: its own, else its section's first; nil, none.
    public static func topic(about settingsTopic: String?) -> HelpTopic? {
        guard let settingsTopic else { return nil }
        let section = String(settingsTopic.prefix { $0 != "." })
        return HelpTopic.allCases.first { $0.settingsTopic == settingsTopic }
            ?? HelpTopic.allCases.first { $0.settingsSection == section }
    }
}
