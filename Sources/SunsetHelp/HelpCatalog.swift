/// Help's texts, by topic (roadmap 0041 A): one source for a control's tooltip (`summary`) and its explanation.
public enum HelpCatalog {
    /// Every topic's text.
    public static let entries: [HelpTopic: HelpEntry] = sidebar.merging(web) { first, _ in first }
        .merging(general) { first, _ in first }

    /// The text of `topic`.
    /// - Parameter topic: The topic.
    /// - Returns: Its entry; a title alone for a topic without text (a gate fails on it).
    public static func entry(_ topic: HelpTopic) -> HelpEntry {
        entries[topic] ?? HelpEntry(title: topic.rawValue, summary: "", text: [])
    }

    /// The topics whose title or text holds every word of `query`, in any case, in the topics' order.
    /// - Parameter query: Words separated by spaces; empty, every topic.
    /// - Returns: The topics found.
    public static func search(_ query: String) -> [HelpTopic] {
        let words = query.lowercased().split(separator: " ")
        return HelpTopic.allCases.filter { topic in
            let text = entry(topic).words
            return words.allSatisfy { text.contains($0) }
        }
    }
}
