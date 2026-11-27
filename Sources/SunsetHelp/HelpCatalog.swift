/// Help's texts, by topic: one source for a control's tooltip (`summary`) and its explanation.
public enum HelpCatalog {
    /// Every topic's text.
    public static let entries: [HelpTopic: HelpEntry] = {
        var combined = sidebar
        for group in [web, general, blocking] {
            combined.merge(group) { first, _ in first }
        }
        combined[.passwords] = HelpEntry(
            title: "Passwords and the vault",
            summary: "Passwords, one-time codes, cards, notes, and attachments sealed locally on this Mac.",
            text: [
                "The Passwords vault lives in the Library sidebar and seals every record on disk with ChaCha20-Poly1305. "
                    + "It unlocks with your master password, Touch ID (when enabled), or your one-time recovery code, and "
                    + "locks automatically on sleep, screen lock, quit, or the timeouts set in **Settings > Passwords**.",
                "While unlocked, Sunset keeps the window out of screen capture, records prior secret values in each "
                    + "field's history, lets you attach files up to 4 MB per item, generates random passwords or Diceware "
                    + "passphrases, and checks for weak or reused passwords offline in **More > Password Health**.",
                "Backups write sealed `.svault` archives; imports accept CSV, Bitwarden JSON, Aegis, 2FAS, and andOTP "
                    + "files inside one atomic vault transaction."
            ],
            related: [.privateBrowsing, .features]
        )
        return combined
    }()

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
