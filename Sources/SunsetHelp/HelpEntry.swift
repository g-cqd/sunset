/// What help says of a topic: its title, a one-sentence summary (the control's tooltip), plain paragraphs, paragraphs for
/// experienced people (folded away until asked for), and the topics it leads to.
public struct HelpEntry: Sendable, Equatable {
    public let title: String
    /// One sentence of at most 110 characters: the tooltip.
    public let summary: String
    /// Plain paragraphs; one starting with "• " is a list item.
    public let text: [String]
    public let expert: [String]
    public let related: [HelpTopic]

    public init(title: String, summary: String, text: [String], expert: [String] = [], related: [HelpTopic] = []) {
        self.title = title
        self.summary = summary
        self.text = text
        self.expert = expert
        self.related = related
    }

    /// Every word of it, lower-cased, for search.
    var words: String {
        ([title, summary] + text + expert).joined(separator: " ").lowercased()
    }
}
