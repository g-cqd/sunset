package import Foundation

/// What is typed into an empty page becomes an address (step a's minimum; the full rules of R1, https first, http for this machine and the local
/// network, a word alone searched, are web step c, t127). A scheme is kept; anything else is tried over https.
package enum WebAddress {
    package static func url(from typed: String) -> URL? {
        let text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains(" ") else { return nil }
        if let url = URL(string: text), let scheme = url.scheme?.lowercased(),
            ["http", "https", "file", "about"].contains(scheme)
        {
            return url
        }
        return URL(string: "https://" + text)
    }

    /// What typed in the command bar is taken for an address (a "Go to" row): a scheme, or one word with a dot between letters, a port or a slash
    /// ("example.com", "nas:8080", "nas/"), or "localhost". Words alone are left to the tab search until search engines (web step c).
    package static func typedAddress(_ typed: String) -> URL? {
        let text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains(" ") else { return nil }
        if text.contains("://") || text.hasPrefix("about:") { return url(from: text) }
        let host = text.split(whereSeparator: { $0 == "/" || $0 == ":" }).first.map(String.init) ?? ""
        let dotted = host.split(separator: ".").count > 1 && !host.hasSuffix(".") && host.last?.isLetter == true
        let numeric = host.split(separator: ".").count == 4 && host.allSatisfy { $0.isNumber || $0 == "." }
        let marked = text.contains("/") || text.contains(":")
        guard dotted || numeric || marked || host.lowercased() == "localhost", !host.isEmpty else { return nil }
        return url(from: text)
    }
}
