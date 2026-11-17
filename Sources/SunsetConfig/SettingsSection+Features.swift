extension SettingsSection {
    /// The sections and topics shown with these scopes on (roadmap 0033): the settings of a scope that is off are not
    /// shown, and are not found by a search. The switches themselves always are.
    public static func sections(for features: Configuration.Features) -> [Self] {
        all.compactMap { section in
            guard shows(section.id, features) else { return nil }
            let topics = section.topics.filter { shows($0.id, features) }
            return topics.isEmpty
                ? nil : Self(id: section.id, title: section.title, symbol: section.symbol, topics: topics)
        }
    }

    /// Whether a section, or a topic, is of a scope that is on.
    static func shows(_ id: String, _ features: Configuration.Features) -> Bool {
        switch id {
            case "terminal", "privacy.programs": features.terminal
            case "web", "privacy.browsing": features.web
            case "general.documents": features.documents
            default: true
        }
    }

    /// Whether the options of the topic `id` are shown and found: the topic and its section are of scopes that are on.
    public static func showsTopic(_ id: String, _ features: Configuration.Features) -> Bool {
        guard let found = topic(id) else { return true }
        return shows(found.section.id, features) && shows(id, features)
    }
}
