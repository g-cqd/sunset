package import Foundation
import SunsetPane

/// The SF Symbols a person can pick from (R3, step c), read from the system's own data (`CoreGlyphs.bundle`: the order, the search words, the
/// categories, the symbols Apple restricts). Read when the icon popover opens and dropped when it closes. The files are the system's, not an API: when
/// they are missing or change shape, the catalog is empty and the popover says so.
package struct SymbolCatalog: Sendable {
    package struct Symbol: Sendable, Equatable, Identifiable {
        package let name: String
        package let keywords: [String]
        package let categories: [String]
        package var id: String { name }
    }

    package static let systemResources = URL(
        fileURLWithPath: "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources"
    )

    package let symbols: [Symbol]
    /// The categories in the system's order, by key, with the symbol that stands for each.
    package let categories: [(key: String, icon: String)]

    package init(symbols: [Symbol], categories: [(key: String, icon: String)] = []) {
        self.symbols = symbols
        self.categories = categories
    }

    /// Reads the catalog from `resources` (the system's by default).
    package static func load(from resources: URL = systemResources) -> SymbolCatalog {
        func plist(_ name: String) -> Any? {
            guard let data = try? Data(contentsOf: resources.appending(path: name)) else { return nil }
            return try? PropertyListSerialization.propertyList(from: data, format: nil)
        }
        let order = plist("symbol_order.plist") as? [String] ?? []
        let search = plist("symbol_search.plist") as? [String: [String]] ?? [:]
        let inCategory = plist("symbol_categories.plist") as? [String: [String]] ?? [:]
        let restricted = Set((plist("symbol_restrictions.strings") as? [String: String] ?? [:]).keys)
        let categoryList = (plist("categories.plist") as? [[String: String]] ?? [])
            .compactMap { entry -> (String, String)? in
                guard let key = entry["key"], let icon = entry["icon"] else { return nil }
                return (key, icon)
            }
        let names = Set(order)
        // A symbol drawn for one script (`character.ar`, `0.circle.hi`): the scripts are the suffixes `character` has.
        let scripts = Set(
            order.compactMap { name -> String? in
                guard name.hasPrefix("character.") else { return nil }
                let rest = name.dropFirst("character.".count)
                return rest.contains(".") || rest.count > 3 ? nil : String(rest)
            }
        )
        let symbols = order.compactMap { name -> Symbol? in
            guard !restricted.contains(name) else { return nil }
            if let dot = name.lastIndex(of: "."), scripts.contains(String(name[name.index(after: dot)...])),
                names.contains(String(name[..<dot]))
            {
                return nil
            }
            return Symbol(name: name, keywords: search[name] ?? [], categories: inCategory[name] ?? [])
        }
        return SymbolCatalog(symbols: symbols, categories: categoryList)
    }

    /// The symbols for what was typed, best first, in `category` when one is given ("all" is every one); an empty query keeps the system's order.
    /// Every typed word must begin a word of the name (`rock` finds `rocket` and `rocket.fill`) or of one of its search words;
    /// names score above search words, an exact word above a beginning, a short name above a long one. Only when nothing matches so does the loose match
    /// tabs use (letters in order) give an answer.
    package func search(_ query: String, in category: String? = nil) -> [Symbol] {
        let pool =
            category.map { key in key == "all" ? symbols : symbols.filter { $0.categories.contains(key) } } ?? symbols
        let words = query.lowercased().split(whereSeparator: { $0 == " " || $0 == "." }).map(String.init)
        guard !words.isEmpty else { return pool }
        var scored: [(index: Int, score: Int)] = []
        for (index, symbol) in pool.enumerated() {
            let parts = symbol.name.split(separator: ".").map(String.init)
            let terms = symbol.keywords.flatMap { $0.lowercased().split(separator: " ").map(String.init) }
            var total = 0
            for word in words {
                let best: Int
                if parts.contains(word) {
                    best = 100
                } else if parts.contains(where: { $0.hasPrefix(word) }) {
                    best = 60
                } else if terms.contains(word) {
                    best = 40
                } else if terms.contains(where: { $0.hasPrefix(word) }) {
                    best = 20
                } else {
                    best = 0
                }
                guard best > 0 else {
                    total = 0
                    break
                }
                total += best
            }
            if total > 0 { scored.append((index, total * 10 - parts.count)) }
        }
        if scored.isEmpty {
            let candidates = pool.enumerated()
                .map { index, symbol in
                    TabSearch.Candidate(
                        id: index,
                        fields: [symbol.name.replacingOccurrences(of: ".", with: " ")] + symbol.keywords
                    )
                }
            return TabSearch.rank(query: query, candidates: candidates).map { pool[$0] }
        }
        return scored.sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }.map { pool[$0.index] }
    }
}
