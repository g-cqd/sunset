package import Foundation

/// A notification a page asked to show (roadmap 0035 D), as the app is to post it: its text cleaned (white paper §9).
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
    /// A later one of the page's site with the same tag replaces it (roadmap 0036 E); empty: none.
    package let tag: String
    /// Its picture: an http, https or data address only (roadmap 0036 E).
    package let icon: URL?

    init(id: Int, title: String, body: String, host: String, tag: String = "", icon: String? = nil) {
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
