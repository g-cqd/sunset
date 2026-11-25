package import Foundation

/// An extension named by a store's page: the Chrome Web Store's (its 32-letter id), Firefox Add-ons' (its slug). Sunset
/// fetches the package from the store itself (probed 2026-11-20): Chrome's update service answers a CRX3 for an id; Firefox
/// Add-ons' API names the `.xpi` of the current version. HTTPS only.
package enum ExtensionStoreLink: Equatable, Sendable {
    case chrome(id: String)
    case firefox(slug: String)

    package init?(_ url: URL) {
        guard url.scheme == "https", let host = url.host() else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch host {
            case "chromewebstore.google.com":
                // /detail/<name>/<id>, or /detail/<id>
                guard parts.first == "detail", let id = parts.last, Self.isChromeID(id) else { return nil }
                self = .chrome(id: id)
            case "chrome.google.com":
                guard parts.count >= 3, parts[0] == "webstore", parts[1] == "detail", let id = parts.last,
                    Self.isChromeID(id)
                else { return nil }
                self = .chrome(id: id)
            case "addons.mozilla.org":
                // /<locale>/firefox/addon/<slug>/
                guard let at = parts.firstIndex(of: "addon"), at + 1 < parts.count, at >= 1, parts[at - 1] == "firefox"
                else { return nil }
                self = .firefox(slug: parts[at + 1])
            default: return nil
        }
    }

    package var isFirefox: Bool {
        if case .firefox = self { true } else { false }
    }

    /// Chrome's ids: 32 letters from a to p.
    static func isChromeID(_ text: String) -> Bool {
        text.count == 32 && text.allSatisfy { ("a" ... "p").contains($0) }
    }

    /// Where the package is fetched from: Chrome's update service (it redirects to the CRX), Firefox Add-ons' API (it names
    /// the `.xpi`, read by `firefoxPackage(fromAPI:)`).
    package var source: URL {
        switch self {
            case .chrome(let id):
                var parts = URLComponents(string: "https://clients2.google.com/service/update2/crx")
                parts?.percentEncodedQuery =
                    "response=redirect&prodversion=140.0.0.0&acceptformat=crx2,crx3&x=id%3D\(id)%26uc"
                return parts?.url ?? URL(filePath: "/")
            case .firefox(let slug):
                let escaped = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? slug
                return URL(string: "https://addons.mozilla.org/api/v5/addons/addon/\(escaped)/") ?? URL(filePath: "/")
        }
    }

    /// The `.xpi` the API names for the current version; nil unless HTTPS on Mozilla's Add-ons host (N-S4).
    package static func firefoxPackage(fromAPI data: Data) -> URL? {
        struct Answer: Decodable {
            struct Version: Decodable {
                struct File: Decodable { let url: URL }
                let file: File
            }
            let current_version: Version
        }
        guard let url = try? JSONDecoder().decode(Answer.self, from: data).current_version.file.url,
            ExtensionPackage.isTrustedFirefoxDownload(url)
        else { return nil }
        return url
    }
}
