package import Foundation

/// What was typed where an address goes (R1, web step c): an address, or words to search with an engine.
package enum WebInput: Equatable, Sendable {
    /// `guessed`: no scheme was typed and https was tried first (the http setting may then fall back).
    case address(URL, guessed: Bool)
    case search(SearchEngine, words: String)

    /// The rules of R1: a scheme is kept; this machine and the local network (localhost and loopback, `.local` names, private ranges, one label with a
    /// port or a slash) go over http at once; another host with a dot goes over https; one word alone, or several, is searched, with the engine whose
    /// keyword starts what was typed ("ddg words"), else `engine`.
    package static func parse(_ typed: String, engine: SearchEngine, engines: [SearchEngine]) -> WebInput? {
        let text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if let space = text.firstIndex(of: " "),
            let chosen = engines.first(where: { $0.keyword.lowercased() == text[..<space].lowercased() })
        {
            let words = text[space...].trimmingCharacters(in: .whitespaces)
            return words.isEmpty ? nil : .search(chosen, words: words)
        }
        if !text.contains(" "), let url = address(text) { return url }
        return .search(engine, words: text)
    }

    static func address(_ text: String) -> WebInput? {
        if let url = URL(string: text), let scheme = url.scheme?.lowercased(),
            ["http", "https", "file", "about"].contains(scheme), text.contains(":/") || scheme == "about"
        {
            return .address(url, guessed: false)
        }
        let host = LocalHost.host(of: text)
        guard !host.isEmpty else { return nil }
        let marked = text.dropFirst(host.count).first.map { $0 == ":" || $0 == "/" } ?? false
        if LocalHost.isLocal(host) || (!host.contains(".") && marked) {
            return URL(string: "http://" + text).map { .address($0, guessed: false) }
        }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        let numeric = labels.count == 4 && labels.allSatisfy { !$0.isEmpty && $0.allSatisfy(\.isNumber) }
        guard labels.count > 1, labels.allSatisfy({ !$0.isEmpty }), labels.last?.first?.isLetter == true || numeric
        else {
            return nil
        }
        return URL(string: "https://" + text).map { .address($0, guessed: true) }
    }

    /// The address to load.
    package var url: URL? {
        switch self {
            case .address(let url, _): url
            case .search(let engine, let words): engine.searchURL(words)
        }
    }
}
