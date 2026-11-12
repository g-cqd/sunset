import Foundation

/// How well an element answers a query, in tiers: 1 exact name, 2 a name starting with it, 3 a word of a name starting with it, 4 a name holding it,
/// 5 its letters in order (fuzzy). Within a tier the score orders: the better the field (title before help), an actionable role, enabled, visible.
struct Match {
    let node: Node
    let tier: Int
    let score: Double
}

enum Ranking {
    static let actionable: Set<String> = [
        "AXButton", "AXMenuItem", "AXMenuBarItem", "AXTextField", "AXTextArea", "AXCheckBox", "AXRadioButton",
        "AXPopUpButton",
        "AXLink", "AXComboBox", "AXSearchField", "AXSlider", "AXTab", "AXRow", "AXCell", "AXDisclosureTriangle",
        "AXMenuButton"
    ]

    static func rank(_ nodes: [Node], query: String, role: String?) -> [Match] {
        let wanted = normalized(query)
        var matches: [Match] = []
        for node in nodes {
            if let role, node.role.lowercased() != role.lowercased(), node.role.lowercased() != "ax" + role.lowercased()
            {
                continue
            }
            let found = node.names.enumerated()
                .compactMap { field, name in
                    tier(normalized(name), wanted).map { (tier: $0, field: field) }
                }
            guard let best = found.min(by: { ($0.tier, $0.field) < ($1.tier, $1.field) }) else { continue }
            var score = 100 - Double(best.tier) * 15 - Double(best.field) * 3
            if actionable.contains(node.role) { score += 8 }
            if !node.enabled { score -= 25 }
            if let frame = node.frame, frame.width < 1 || frame.height < 1 { score -= 20 }
            if node.frame == nil { score -= 5 }
            matches.append(Match(node: node, tier: best.tier, score: score))
        }
        return matches.sorted { $0.tier != $1.tier ? $0.tier < $1.tier : $0.score > $1.score }
    }

    static func tier(_ name: String, _ query: String) -> Int? {
        guard !query.isEmpty, !name.isEmpty else { return nil }
        if name == query { return 1 }
        if name.hasPrefix(query) { return 2 }
        if name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains(where: { $0.hasPrefix(query) }) {
            return 3
        }
        if name.contains(query) { return 4 }
        var rest = Substring(name)
        for character in query {
            guard let found = rest.firstIndex(of: character) else { return nil }
            rest = rest[rest.index(after: found)...]
        }
        return query.count >= 3 ? 5 : nil
    }

    /// Lower case, no accents, the typographer's quotes and ellipsis made plain.
    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "\u{2019}", with: "'").replacingOccurrences(of: "\u{2026}", with: "...")
            .trimmingCharacters(in: .whitespaces)
    }

    /// The best match, when it stands out: alone in the best tier, or ahead of the next by a clear score.
    static func clearWinner(_ matches: [Match]) -> Match? {
        // Letters in order alone is never certain enough to act on.
        guard let first = matches.first, first.tier <= 4 else { return nil }
        guard matches.count > 1 else { return first }
        let second = matches[1]
        return second.tier > first.tier || first.score - second.score >= 10 ? first : nil
    }
}
