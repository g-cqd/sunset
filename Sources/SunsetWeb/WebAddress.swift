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
}
