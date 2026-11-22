public import Foundation

/// The extensions of a Firefox profile, from its `extensions.json`.
public enum FirefoxExtensions {
    private struct File: Decodable {
        let addons: [Addon]
    }

    private struct Addon: Decodable {
        struct Locale: Decodable {
            let name: String?
        }

        let id: String
        let type: String?
        let location: String?
        let userDisabled: Bool?
        let defaultLocale: Locale?
    }

    /// The person's extensions (Firefox's own, built in or from the system, and themes and dictionaries left out), with
    /// their add-ons page, in the file's order.
    public static func read(_ data: Data) throws -> [BrowserExtension] {
        try JSONDecoder().decode(File.self, from: data).addons
            .compactMap { addon in
                guard addon.type == "extension", addon.location == "app-profile" else { return nil }
                let path = addon.id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? addon.id
                return BrowserExtension(
                    id: addon.id,
                    name: addon.defaultLocale?.name ?? addon.id,
                    store: URL(string: "https://addons.mozilla.org/firefox/addon/\(path)/"),
                    isEnabled: addon.userDisabled != true
                )
            }
    }
}
