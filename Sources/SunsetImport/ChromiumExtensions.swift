public import Foundation

/// The extensions of a Chromium profile, from its `Extensions` folder (roadmap 0111 F).
public enum ChromiumExtensions {
    private struct Manifest: Decodable {
        private enum CodingKeys: String, CodingKey {
            case name
            case defaultLocale = "default_locale"
        }

        let name: String?
        let defaultLocale: String?
    }

    private struct Message: Decodable {
        let message: String
    }

    /// Each extension's newest version: its name (a localized one looked up), its Chrome Web Store page; by name.
    public static func read(profile: URL) -> [BrowserExtension] {
        let folder = profile.appending(path: "Extensions")
        let ids = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        return ids.filter(isExtensionID)
            .compactMap { id in
                let versions =
                    (try? FileManager.default.contentsOfDirectory(atPath: folder.appending(path: id).path)) ?? []
                guard let newest = versions.max(by: { order($0).lexicographicallyPrecedes(order($1)) }) else {
                    return nil
                }
                let root = folder.appending(path: id).appending(path: newest)
                guard let data = try? Data(contentsOf: root.appending(path: "manifest.json")),
                    let manifest = try? JSONDecoder().decode(Manifest.self, from: data), let written = manifest.name
                else { return nil }
                let name = localized(written, in: root, locale: manifest.defaultLocale)
                return BrowserExtension(
                    id: id,
                    name: name,
                    store: URL(string: "https://chromewebstore.google.com/detail/\(id)")
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The extensions Chrome installs by itself (Web Store Payments, Google's apps): not the person's choice.
    static let chromesOwn: Set<String> = [
        "nmmhkkegccagdldgiimedpiccmgmieda", "ghbmnnjooekpmoecnnnilnnbdlolhkhi", "pjkljhegncpnkpknbcohdijeoejaedia",
        "apdfllckaahabafndbhieahigkjlhalf", "blpcfgokakmgnkcojhhkbfbldkacnbeo", "aohghmighlieiainnegkcijnfilokake",
        "felcaaldnbdncclmgdcncolpebgiejap", "aapocclcgogkmnckokdopfmhonfmgoek", "coobgpohoikkiipiblmjeljniedjpjpf"
    ]

    /// An extension's id (32 letters from a to p), and not one of Chrome's own.
    static func isExtensionID(_ name: String) -> Bool {
        name.count == 32 && name.allSatisfy { ("a" ... "p").contains($0) } && !chromesOwn.contains(name)
    }

    /// A version folder's order: "1.60.0_0" as its numbers.
    private static func order(_ folder: String) -> [Int] {
        folder.split { $0 == "." || $0 == "_" }.map { Int($0) ?? 0 }
    }

    private static func localized(_ name: String, in root: URL, locale: String?) -> String {
        guard name.hasPrefix("__MSG_"), name.hasSuffix("__"), let locale else { return name }
        let key = name.dropFirst(6).dropLast(2).lowercased()
        let file = root.appending(path: "_locales").appending(path: locale).appending(path: "messages.json")
        guard let data = try? Data(contentsOf: file),
            let messages = try? JSONDecoder().decode([String: Message].self, from: data),
            let found = messages.first(where: { $0.key.lowercased() == key })
        else { return name }
        return found.value.message
    }
}
