import Foundation
import SunsetPrivate
package import SunsetShell

/// What a page's tab shows (its title, its picture) and what finds it.
extension WebContent {
    package var title: String { pageTitle.isEmpty ? (url?.host() ?? "New Page") : pageTitle }
    /// No second line in a tab: the address is in the address field (owner note n62); the address is still searched by (`searchTerms`).
    package var detail: String? { nil }
    package var searchTerms: [String] { url.map { [$0.absoluteString] } ?? [] }
    package var closeWarning: String? { nil }

    package var glyph: PaneGlyph {
        if isPrivate { return .symbol("eye.slash") }
        if settings.favicons, let favicon { return .image(favicon) }
        guard settings.initialIcon, let first = title.first(where: \.isLetter) else { return .symbol("globe") }
        return .initial(String(first).uppercased())
    }

    /// Muted for as long as the person leaves it so, playing or not: the speaker stays to unmute it.
    package var sound: PaneSound? { isMuted ? .muted : playsSound ? .playing : nil }

    package func toggleMuted() {
        guard let webView else { return }
        isMuted.toggle()
        WebAudio.setMuted(isMuted, on: webView)
    }
}
