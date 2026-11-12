package import Foundation

/// A search engine (web step c): its name, the keyword that picks it ("ddg words"), its search address and, when it has one in the OpenSearch JSON
/// format, its suggestion address; `%s` stands for the words.
package struct SearchEngine: Sendable, Equatable, Hashable {
    package var name: String
    package var keyword: String
    package var search: String
    package var suggest: String?

    package init(name: String, keyword: String, search: String, suggest: String? = nil) {
        self.name = name
        self.keyword = keyword
        self.search = search
        self.suggest = suggest
    }

    /// The engines that come with Sunset (the owner's list). Bing has no suggestion address: its OpenSearch one answers nothing (2026-11-12).
    package static let builtIn: [SearchEngine] = [
        SearchEngine(
            name: "Google",
            keyword: "g",
            search: "https://www.google.com/search?q=%s",
            suggest: "https://suggestqueries.google.com/complete/search?client=firefox&q=%s"
        ),
        SearchEngine(
            name: "DuckDuckGo",
            keyword: "ddg",
            search: "https://duckduckgo.com/?q=%s",
            suggest: "https://duckduckgo.com/ac/?q=%s&type=list"
        ),
        SearchEngine(name: "Bing", keyword: "bing", search: "https://www.bing.com/search?q=%s"),
        SearchEngine(
            name: "Ecosia",
            keyword: "eco",
            search: "https://www.ecosia.org/search?q=%s",
            suggest: "https://ac.ecosia.org/autocomplete?q=%s&type=list"
        ),
        SearchEngine(
            name: "Kagi",
            keyword: "kagi",
            search: "https://kagi.com/search?q=%s",
            suggest: "https://kagi.com/api/autosuggest?q=%s"
        )
    ]

    /// The address that searches `words`.
    package func searchURL(_ words: String) -> URL? { Self.fill(search, words) }

    /// The address that asks for suggestions for `words`.
    package func suggestURL(_ words: String) -> URL? { suggest.flatMap { Self.fill($0, words) } }

    static func fill(_ template: String, _ words: String) -> URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?#")
        guard let encoded = words.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        return URL(string: template.replacingOccurrences(of: "%s", with: encoded))
    }
}
