package import Foundation

/// A notification a page asked to show, as the app is to post it: its text cleaned (white paper §9).
package struct WebNotification: Sendable, Equatable {
    /// The longest title and body shown: what a notification shows of them, and no more is kept.
    package static let titleLimit = 120
    package static let bodyLimit = 400

    /// The page's number for it: what a click on it is told back with.
    package let id: Int
    package let title: String
    package let body: String
    /// The site that showed it (from WebKit, not from the page).
    package let host: String
    /// A later one of the page's site with the same tag replaces it; empty: none.
    package let tag: String
    /// Its picture: an http, https or data address only.
    package let icon: URL?
    /// The page asked for no sound.
    package let silent: Bool

    package init(
        id: Int,
        title: String,
        body: String,
        host: String,
        tag: String = "",
        icon: String? = nil,
        silent: Bool = false
    ) {
        self.silent = silent
        self.id = id
        self.title = String(UntrustedText.oneLine(title).prefix(Self.titleLimit))
        self.body = String(UntrustedText.oneLine(body).prefix(Self.bodyLimit))
        self.host = host
        self.tag = String(UntrustedText.oneLine(tag).prefix(Self.titleLimit))
        self.icon = icon.flatMap(URL.init(string:))
            .flatMap { url in
                ["http", "https", "data"].contains(url.scheme?.lowercased() ?? "") ? url : nil
            }
    }
}
