import Foundation
package import SunsetShell

/// What a page's tab shows (its title, its picture) and what finds it.
extension WebContent {
    package var title: String { pageTitle.isEmpty ? (url?.host() ?? "New Page") : pageTitle }
    /// No second line in a tab: the address is in the address field (owner note n62); the address is still searched by (`searchTerms`).
    package var detail: String? { nil }
    package var searchTerms: [String] { url.map { [$0.absoluteString] } ?? [] }
    package var closeWarning: String? { nil }

    package var glyph: PaneGlyph {
        if isPrivate { return .symbol("theatermasks") }
        guard settings.initialIcon, let first = title.first(where: \.isLetter) else { return .symbol("globe") }
        return .initial(String(first).uppercased())
    }
}
