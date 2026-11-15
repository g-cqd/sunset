/// A section of Settings and its topics (roadmap 0032; the review of 2026-11-15, 5.3, with the owner's changes): the sidebar
/// lists the sections, and under the one shown its topics; a topic is a page.
public struct SettingsSection: Sendable, Identifiable {
    public let id: String
    public let title: String
    /// An SF Symbol.
    public let symbol: String
    public let topics: [SettingsTopic]

    /// What the sidebar's row of a section is tagged with, before the section's identifier.
    public static let sectionPrefix = "section:"

    /// The topic `id` and its section.
    /// - Complexity: O(topics).
    public static func topic(_ id: String) -> (section: Self, topic: SettingsTopic)? {
        for section in all {
            if let topic = section.topics.first(where: { $0.id == id }) { return (section, topic) }
        }
        return nil
    }

    /// What a search result is under: its section and its topic; the identifier itself when it names no topic.
    public static func heading(of topic: String) -> String {
        guard let found = Self.topic(topic) else { return topic }
        return found.section.title + " \u{203A} " + found.topic.title
    }

    /// The topic to show for what is chosen in the sidebar: a topic itself, or the first topic of a section's row.
    public static func shown(for selection: String?) -> String? {
        guard let selection else { return nil }
        guard selection.hasPrefix(sectionPrefix) else { return topic(selection)?.topic.id }
        let section = selection.dropFirst(sectionPrefix.count)
        return all.first { $0.id == section }?.topics.first?.id
    }
}
